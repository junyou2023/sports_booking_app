import os

import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status

from sports.models import Slot, Booking

stripe.api_key = os.getenv('STRIPE_API_KEY', '')


class StripeCheckoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        slot_id = request.data.get('slot')
        if not slot_id:
            return Response({'detail': 'slot required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            slot = Slot.objects.get(pk=slot_id)
        except Slot.DoesNotExist:
            return Response({'detail': 'invalid slot'}, status=status.HTTP_400_BAD_REQUEST)

        if not stripe.api_key:
            return Response({'detail': 'server misconfigured: STRIPE_API_KEY missing'}, status=500)

        try:
            intent = stripe.PaymentIntent.create(
                amount=int(slot.price * 100),
                currency='usd',
                automatic_payment_methods={'enabled': True},
                metadata={'slot_id': slot_id, 'user_id': request.user.id},
            )
        except stripe.error.StripeError as e:
            return Response({'detail': str(e)}, status=status.HTTP_502_BAD_GATEWAY)
        except Exception as e:
            return Response({'detail': 'unexpected error: ' + str(e)}, status=500)

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
            },
            status=200,
        )

    def get(self, request):
        return Response({'detail': 'not implemented'}, status=405)

class StripeWebhookView(APIView):
    permission_classes = [AllowAny]

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
