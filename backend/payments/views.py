import os
import logging
import stripe
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status

from sports.models import Slot, Booking
from sports.serializers import BookingSerializer

stripe.api_key = os.getenv("STRIPE_API_KEY", "")
logger = logging.getLogger(__name__)


class StripeCheckoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        slot_id = request.data.get("slot")
        if not slot_id:
            return Response({"detail": "slot required"}, status=400)
        try:
            slot = Slot.objects.get(pk=slot_id)
        except Slot.DoesNotExist:
            return Response({"detail": "invalid slot"}, status=400)

        if not stripe.api_key or stripe.api_key.endswith("xxx"):
            return Response(
                {"detail": "server misconfigured: STRIPE_API_KEY missing"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        if Booking.objects.filter(slot=slot, user=request.user).exists():
            return Response({"detail": "booking already exists"}, status=409)

        try:
            intent = stripe.PaymentIntent.create(
                amount=int(slot.price * 100),
                currency="usd",
                automatic_payment_methods={"enabled": True},
                metadata={"slot_id": slot_id, "user_id": request.user.id},
            )
        except stripe.error.StripeError as e:
            logger.exception("Failed to create PaymentIntent")
            return Response({"detail": str(e)}, status=400)

        return Response(
            {"client_secret": intent.client_secret, "intent_id": intent.id},
            status=200,
        )

    def get(self, request):
        return Response({'detail': 'not implemented'}, status=405)

class StripeWebhookView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        payload = request.body
        sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
        secret = os.getenv("STRIPE_WEBHOOK_SECRET", "")

        if not secret:
            logger.warning("STRIPE_WEBHOOK_SECRET not set; webhook verification skipped")
            return Response({"detail": "webhook disabled"}, status=status.HTTP_200_OK)

        try:
            event = stripe.Webhook.construct_event(payload, sig_header, secret)
        except stripe.error.SignatureVerificationError:
            return Response({"detail": "invalid webhook signature"}, status=400)
        except Exception:
            return Response({"detail": "invalid payload"}, status=400)

        if event["type"] == "payment_intent.succeeded":
            intent = event["data"]["object"]
            slot_id = intent["metadata"].get("slot_id")
            user_id = intent["metadata"].get("user_id")
            booking, created = Booking.objects.get_or_create(
                slot_id=slot_id,
                user_id=user_id,
                defaults={
                    "activity_id": Slot.objects.filter(pk=slot_id).values_list("activity_id", flat=True).first(),
                    "payment_intent_id": intent["id"],
                    "status": "confirmed",
                    "paid": True,
                },
            )
            if not created and not booking.paid:
                booking.paid = True
                booking.status = "confirmed"
                booking.payment_intent_id = intent["id"]
                booking.save(update_fields=["paid", "status", "payment_intent_id"])
            logger.info("Booking %s confirmed via webhook", booking.id)

        return Response({"status": "ok"})


class StripeConfirmView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, intent_id):
        booking = Booking.objects.filter(
            payment_intent_id=intent_id, user=request.user
        ).first()
        if not booking:
            return Response({"detail": "booking not found"}, status=404)

        ser = BookingSerializer(booking)
        return Response(ser.data)
