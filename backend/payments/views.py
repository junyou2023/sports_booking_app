import os
import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError

from sports.models import Slot, Booking

stripe.api_key = os.getenv('STRIPE_API_KEY', '')


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

        if not stripe.api_key or stripe.api_key.endswith('xxx'):
            return Response(
                {'detail': 'server misconfigured: STRIPE_API_KEY missing/invalid'},
                status=500,
            )

        try:
            intent = stripe.PaymentIntent.create(
                amount=int(slot.price * 100),
                currency='usd',
                automatic_payment_methods={'enabled': True},
                metadata={'slot_id': slot_id, 'user_id': request.user.id},
            )
        except stripe.error.StripeError as e:
            return Response({'detail': str(e)}, status=400)
        except Exception as e:
            return Response({'detail': f'server error: {e}'}, status=500)

        return Response(
            {
                'client_secret': intent.client_secret,
                'intent_id': intent.id,
            },
            status=200,
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
            return Response({'detail': 'webhook secret missing'}, status=500)

        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, secret
            )
        except stripe.error.SignatureVerificationError:
            return Response({'detail': 'invalid webhook signature'}, status=400)
        except Exception:
            return Response({'detail': 'invalid payload'}, status=400)

        if event['type'] == 'payment_intent.succeeded':
            intent = event['data']['object']
            slot_id = intent['metadata'].get('slot_id')
            user_id = intent['metadata'].get('user_id')
            try:
                slot = Slot.objects.get(pk=slot_id)
                Booking.objects.create(
                    slot=slot,
                    activity=slot.activity,
                    user_id=user_id,
                    status='confirmed',
                    paid=True,
                    pax=1,
                )
            except IntegrityError:
                Booking.objects.filter(slot_id=slot_id, user_id=user_id).update(
                    paid=True, status='confirmed'
                )
        return Response({'status': 'ok'})
