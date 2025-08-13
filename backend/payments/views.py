import os, logging
from decimal import Decimal, InvalidOperation
from django.db import transaction, IntegrityError
from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
import stripe

from sports.models import Slot, Booking
from sports.serializers import BookingSerializer

logger = logging.getLogger(__name__)
stripe.api_key = os.getenv("STRIPE_API_KEY", "")


class StripeCheckoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # 全局兜底：任何异常都返回 JSON，绝不“connection closed”
        try:
            return self._post_impl(request)
        except Exception as e:
            logger.exception("Unhandled error in /payments/checkout/")
            return Response(
                {"detail": "internal_error", "error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def _post_impl(self, request):
        # 0) Key 预检
        if not stripe.api_key or stripe.api_key.endswith("xxx"):
            return Response({"detail": "Stripe secret key is not configured"}, status=500)

        # 1) 取 slot 并校验
        slot_id = request.data.get("slot")
        if not slot_id:
            return Response({"detail": "slot required"}, status=400)
        try:
            slot = Slot.objects.get(pk=slot_id)
        except Slot.DoesNotExist:
            return Response({"detail": "invalid slot"}, status=404)
        if getattr(slot, "is_active", True) is False:
            return Response({"detail": "slot inactive"}, status=400)

        # 2) 金额规范化：四舍五入到“分”，并校验 Stripe 最小 50 分
        try:
            price = Decimal(str(slot.price or 0))
            amount_cents = int((price * 100).quantize(Decimal("1")))
        except (InvalidOperation, ValueError):
            return Response({"detail": "invalid price on slot"}, status=500)
        if amount_cents < 50:
            return Response({"detail": "amount must be >= 50 cents"}, status=400)

        # 3) 并发安全地获取/创建 booking
        try:
            with transaction.atomic():
                booking, _ = Booking.objects.get_or_create(
                    slot=slot,
                    user=request.user,
                    defaults={
                        "activity": slot.activity,
                        "status": "pending",
                        "paid": False,
                        "price": slot.price,
                    },
                )
        except IntegrityError:
            booking = Booking.objects.filter(slot=slot, user=request.user).first()

        if booking is None:
            try:
                booking = Booking.objects.create(
                    slot=slot,
                    user=request.user,
                    activity=slot.activity,
                    status="pending",
                    paid=False,
                    price=slot.price,
                )
            except Exception as e:
                logger.exception("Booking creation failed")
                return Response(
                    {"detail": "booking_create_failed", "error": str(e)},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

        # 4) 复用旧 intent；若失效则自愈重建
        intent = None
        if booking.payment_intent_id:
            try:
                intent = stripe.PaymentIntent.retrieve(booking.payment_intent_id)
            except Exception:
                intent = None  # 自愈：后面重建

        if intent is None:
            try:
                intent = stripe.PaymentIntent.create(
                    amount=amount_cents,
                    currency="usd",
                    automatic_payment_methods={"enabled": True},
                    metadata={"slot_id": str(slot.id), "user_id": str(request.user.id)},
                    idempotency_key=f"user:{request.user.id}:slot:{slot.id}",
                    description=f"Booking slot {slot.id} for user {request.user.id}",
                )
                booking.payment_intent_id = intent.id
                booking.save(update_fields=["payment_intent_id"])
            except Exception as e:
                logger.exception("Create PaymentIntent failed")
                return Response({"detail": str(e)}, status=status.HTTP_502_BAD_GATEWAY)

        # 5) 成功返回
        return Response(
            {
                "client_secret": intent.client_secret,
                "payment_intent_id": intent.id,
                "booking_id": booking.id,
            },
            status=200,
        )

class StripeWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE', '')
        secret = os.getenv('STRIPE_WEBHOOK_SECRET', '')

        if not secret:
            logger.warning('STRIPE_WEBHOOK_SECRET not set; webhook verification skipped')
            return Response({'detail': 'webhook disabled'}, status=status.HTTP_200_OK)

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
            bid = Booking.objects.filter(payment_intent_id=intent['id']).first()
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
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, intent_id):
        try:
            intent = stripe.PaymentIntent.retrieve(intent_id)
        except stripe.error.StripeError as e:
            logger.exception('Stripe retrieve failed')
            return Response({'detail': str(e)}, status=status.HTTP_502_BAD_GATEWAY)

        booking = Booking.objects.filter(payment_intent_id=intent_id, user=request.user).first()
        if not booking:
            return Response({'detail': 'booking not found'}, status=status.HTTP_404_NOT_FOUND)

        if intent.status == 'succeeded' and not booking.paid:
            booking.paid = True
            booking.status = 'confirmed'
            booking.save(update_fields=['paid', 'status'])

        ser = BookingSerializer(booking)
        return Response(ser.data)
