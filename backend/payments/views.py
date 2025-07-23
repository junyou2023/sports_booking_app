import os

import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

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
            booking = Booking.objects.filter(slot_id=slot_id, user_id=user_id).first()
            if booking:
                booking.paid = True
                booking.status = 'confirmed'
                booking.save(update_fields=['paid', 'status'])
        return Response({'status': 'ok'})
