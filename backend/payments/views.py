import os
import logging
import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status

try:  # Allow running from repo root or backend/ dir
    from sports.models import Slot, Booking
    from sports.serializers import BookingSerializer
except ModuleNotFoundError:  # pragma: no cover - alternate import path
    from backend.sports.models import Slot, Booking  # type: ignore
    from backend.sports.serializers import BookingSerializer  # type: ignore

# ``stripe`` does not read the secret key from the environment automatically
# for every request.  Previously the module set ``stripe.api_key`` at import
# time, which made it difficult to override in tests and caused the view to
# attempt a network call even when the key was missing.  Instead, resolve the
# key on each request so the behaviour is deterministic and easy to mock.
logger = logging.getLogger(__name__)


class StripeCheckoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        slot_id = request.data.get('slot')
        if not slot_id:
            return Response({'detail': 'slot required'}, status=400)
        try:
            slot = Slot.objects.get(pk=slot_id)
        except Slot.DoesNotExist:
            return Response({'detail': 'invalid slot'}, status=400)

        # Resolve API key each time so tests can override it and to avoid
        # hitting Stripe's API when the key is missing.
        api_key = (
            getattr(stripe, 'api_key', None)
            or os.getenv('STRIPE_API_KEY', '').strip()
        )
        if not api_key or api_key.endswith('xxx'):
            return Response(
                {'detail': 'Stripe secret key is not configured'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        stripe.api_key = api_key

        booking, created = Booking.objects.get_or_create(
            slot=slot,
            user=request.user,
            defaults={
                'activity': slot.activity,
                'status': 'pending',
                'paid': False,
            },
        )

        if booking.payment_intent_id:
            try:
                intent = stripe.PaymentIntent.retrieve(
                    booking.payment_intent_id
                )
            except stripe.error.StripeError as e:
                logger.exception('Failed to retrieve PaymentIntent')
                return Response(
                    {'detail': str(e)},
                    status=status.HTTP_502_BAD_GATEWAY,
                )
        else:
            try:
                intent = stripe.PaymentIntent.create(
                    amount=int(slot.price * 100),
                    currency='usd',
                    automatic_payment_methods={'enabled': True},
                    metadata={'slot_id': slot_id, 'user_id': request.user.id},
                )
                booking.payment_intent_id = intent.id
                booking.save(update_fields=['payment_intent_id'])
            except stripe.error.APIConnectionError:
                logger.exception('Failed to connect to Stripe')
                return Response(
                    {'detail': 'Stripe secret key is misconfigured'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )
            except stripe.error.StripeError as e:
                logger.exception('Failed to create PaymentIntent')
                return Response(
                    {'detail': str(e)},
                    status=status.HTTP_502_BAD_GATEWAY,
                )
            except Exception:
                logger.exception('Error creating PaymentIntent')
                return Response(
                    {'detail': 'internal error'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

        return Response(
            {
                'client_secret': intent.client_secret,
                'payment_intent_id': intent.id,
                'booking_id': booking.id,
            },
            status=status.HTTP_200_OK,
        )

    def get(self, request):
        return Response({'detail': 'not implemented'}, status=405)


class StripeWebhookView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE', '')
        secret = os.getenv('STRIPE_WEBHOOK_SECRET', '')

        if not secret:
            logger.warning(
                'STRIPE_WEBHOOK_SECRET not set; webhook verification skipped'
            )
            return Response(
                {'detail': 'webhook disabled'},
                status=status.HTTP_200_OK,
            )

        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, secret
            )
        except stripe.error.SignatureVerificationError:
            return Response(
                {'detail': 'invalid webhook signature'},
                status=400,
            )
        except Exception:
            return Response({'detail': 'invalid payload'}, status=400)

        if event['type'] == 'payment_intent.succeeded':
            intent = event['data']['object']
            bid = Booking.objects.filter(
                payment_intent_id=intent['id']
            ).first()
            if not bid:
                bid = Booking.objects.filter(
                    slot_id=intent['metadata'].get('slot_id'),
                    user_id=intent['metadata'].get('user_id'),
                ).first()
            if bid and not bid.paid:
                bid.paid = True
                bid.status = 'confirmed'
                bid.save(update_fields=['paid', 'status'])
                logger.info('Booking %s confirmed via webhook', bid.id)
            else:
                logger.warning('No booking found for intent %s', intent['id'])

        return Response({'status': 'ok'})


class StripeConfirmView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, intent_id):
        try:
            intent = stripe.PaymentIntent.retrieve(intent_id)
        except stripe.error.StripeError as e:
            logger.exception('Stripe retrieve failed')
            return Response(
                {'detail': str(e)},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        booking = Booking.objects.filter(
            payment_intent_id=intent_id,
            user=request.user,
        ).first()
        if not booking:
            return Response(
                {'detail': 'booking not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if intent.status == 'succeeded' and not booking.paid:
            booking.paid = True
            booking.status = 'confirmed'
            booking.save(update_fields=['paid', 'status'])

        ser = BookingSerializer(booking)
        return Response(ser.data)
