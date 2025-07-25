import os
import logging

import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response


from sports.models import Slot, Booking

stripe.api_key = os.getenv('STRIPE_API_KEY', '')


def send_push_notification(user, title, body):
    logger = logging.getLogger('push')
    logger.info('Push to %s: %s - %s', user.username, title, body)


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

        intent = stripe.PaymentIntent.create(
            amount=int(slot.price * 100),
            currency='usd',
            metadata={'slot_id': slot_id, 'user_id': request.user.id},
        )
        booking = Booking.objects.create(
            slot=slot,
            activity=slot.activity,
            user=request.user,
            status="pending",
            paid=False,
            pax=1,
        )
        return Response(
            {
                'client_secret': intent.client_secret,
                'intent_id': intent.id,
                'booking_id': booking.id,
            }
        )

    def get(self, request):
        return Response({'detail': 'not implemented'}, status=405)


class StripeWebhookView(APIView):
    permission_classes = []

    def post(self, request):
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
        secret = os.getenv('STRIPE_WEBHOOK_SECRET', '')
        try:
            event = stripe.Webhook.construct_event(payload, sig_header, secret)
        except Exception:
            return Response({'detail': 'invalid payload'}, status=400)

        if event['type'] == 'payment_intent.succeeded':
            intent = event['data']['object']
            slot_id = intent['metadata'].get('slot_id')
            user_id = intent['metadata'].get('user_id')
            booking = Booking.objects.filter(
                slot_id=slot_id, user_id=user_id
            ).first()
            if booking:
                booking.paid = True
                booking.status = 'confirmed'
                booking.save(update_fields=['paid', 'status'])
                send_push_notification(
                    booking.user,
                    'Payment Success',
                    f'Booking #{booking.id} confirmed',
                )
        elif event['type'] == 'payment_intent.payment_failed':
            intent = event['data']['object']
            slot_id = intent['metadata'].get('slot_id')
            user_id = intent['metadata'].get('user_id')
            booking = Booking.objects.filter(
                slot_id=slot_id, user_id=user_id
            ).first()
            if booking:
                booking.status = 'failed'
                booking.save(update_fields=['status'])
                send_push_notification(
                    booking.user,
                    'Payment Failed',
                    f'Booking #{booking.id} failed',
                )
        elif event['type'] == 'charge.refunded':
            charge = event['data']['object']
            intent_id = charge.get('payment_intent')
            if intent_id:
                intent = stripe.PaymentIntent.retrieve(intent_id)
                slot_id = intent['metadata'].get('slot_id')
                user_id = intent['metadata'].get('user_id')
                booking = Booking.objects.filter(
                    slot_id=slot_id, user_id=user_id
                ).first()
                if booking:
                    booking.status = 'refunded'
                    booking.save(update_fields=['status'])
                    send_push_notification(
                        booking.user,
                        'Payment Refunded',
                        f'Booking #{booking.id} refunded',
                    )
        return Response({'status': 'ok'})
