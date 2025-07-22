import os

import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from sports.models import Slot, Booking
from sports.serializers import BookingSerializer

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
        return Response({'client_secret': intent.client_secret, 'intent_id': intent.id})

    def get(self, request):
        intent_id = request.query_params.get('intent_id')
        if not intent_id:
            return Response({'detail': 'intent_id required'}, status=400)
        intent = stripe.PaymentIntent.retrieve(intent_id)
        if intent.status != 'succeeded':
            return Response({'detail': 'payment not complete'}, status=400)

        slot_id = intent.metadata.get('slot_id')
        try:
            slot = Slot.objects.get(pk=slot_id)
        except Slot.DoesNotExist:
            return Response({'detail': 'invalid slot'}, status=400)

        booking, _ = Booking.objects.get_or_create(
            slot=slot, user=request.user, defaults={"activity": slot.activity}
        )
        booking.paid = True
        booking.status = "confirmed"
        booking.activity = slot.activity
        booking.save(update_fields=["paid", "status", "activity"])
        ser = BookingSerializer(booking)
        return Response(ser.data, status=status.HTTP_201_CREATED)
