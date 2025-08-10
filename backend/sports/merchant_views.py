from rest_framework import viewsets, permissions, serializers, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.pagination import CursorPagination
from django.utils.dateparse import parse_datetime

from drf_spectacular.utils import extend_schema, OpenApiParameter

from accounts.permissions import IsOrgMember, IsVendor
from .models import Slot, PriceRule, Booking
from .serializers import (
    SlotSerializer,
    SlotCreateSerializer,
    SlotUpdateSerializer,
    PriceRuleSerializer,
    BookingSerializer,
)


class MerchantSlotViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsOrgMember]

    def get_queryset(self):
        user = self.request.user
        return Slot.objects.filter(
            activity__organization__members__user=user,
            is_active=True,
        ).select_related("activity")

    def get_serializer_class(self):
        if self.action == "create":
            return SlotCreateSerializer
        if self.action in ("update", "partial_update"):
            return SlotUpdateSerializer
        return SlotSerializer

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active"])


class MerchantSlotBulkDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        ids = request.data.get("ids", [])
        if not isinstance(ids, list):
            raise serializers.ValidationError({"ids": "Must be a list"})
        ids = list({int(i) for i in ids}) if ids else []

        existing = Slot.objects.filter(id__in=ids, is_active=True)
        existing_ids = set(existing.values_list("id", flat=True))
        allowed = existing.filter(activity__organization__members__user=request.user)
        allowed_ids = set(allowed.values_list("id", flat=True))
        deleted = allowed.update(is_active=False)
        not_found = [i for i in ids if i not in existing_ids]
        forbidden = [i for i in ids if i in existing_ids and i not in allowed_ids]
        return Response({
            "deleted": deleted,
            "forbidden": forbidden,
            "not_found": not_found,
        })


class PriceRuleViewSet(viewsets.ModelViewSet):
    serializer_class = PriceRuleSerializer
    permission_classes = [permissions.IsAuthenticated, IsOrgMember]

    def get_queryset(self):
        return PriceRule.objects.filter(
            activity__organization__members__user=self.request.user
        )

    def perform_create(self, serializer):
        activity = serializer.validated_data["activity"]
        if not activity.organization.members.filter(user=self.request.user).exists():
            raise permissions.PermissionDenied("Not a member of this organization")
        serializer.save()


class BookingCursorPagination(CursorPagination):
    page_size = 50
    ordering = "-booked_at"


class MerchantBookingListPaged(generics.ListAPIView):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated, IsVendor]
    pagination_class = BookingCursorPagination

    @extend_schema(
        parameters=[
            OpenApiParameter(
                "status", str, OpenApiParameter.QUERY,
                enum=["pending", "confirmed", "cancelled", "refunded", "completed"],
            ),
            OpenApiParameter("paid", bool, OpenApiParameter.QUERY),
            OpenApiParameter("created_after", str, OpenApiParameter.QUERY),
            OpenApiParameter("created_before", str, OpenApiParameter.QUERY),
            OpenApiParameter("activity_id", int, OpenApiParameter.QUERY),
        ]
    )
    def get(self, request, *args, **kwargs):  # pragma: no cover - delegated to list
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        qs = Booking.objects.filter(
            activity__organization__members__user=self.request.user
        ).select_related("slot", "user", "slot__activity")

        params = self.request.query_params
        status_param = params.get("status")
        if status_param in dict(Booking.BOOKING_STATUS_CHOICES):
            qs = qs.filter(status=status_param)
        paid = params.get("paid")
        if paid is not None:
            if paid.lower() == "true":
                qs = qs.filter(paid=True)
            elif paid.lower() == "false":
                qs = qs.filter(paid=False)
        created_after = params.get("created_after")
        if created_after:
            dt = parse_datetime(created_after)
            if dt:
                qs = qs.filter(booked_at__gte=dt)
        created_before = params.get("created_before")
        if created_before:
            dt = parse_datetime(created_before)
            if dt:
                qs = qs.filter(booked_at__lte=dt)
        activity_id = params.get("activity_id")
        if activity_id:
            qs = qs.filter(activity_id=activity_id)
        return qs.order_by("-booked_at")


class MerchantBookingCancelView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    @extend_schema(request=None, responses=BookingSerializer)
    def post(self, request, pk):
        try:
            booking = Booking.objects.select_related(
                "activity__organization"
            ).get(pk=pk)
        except Booking.DoesNotExist:
            return Response({"detail": "not found"}, status=404)

        if not booking.activity.organization.members.filter(user=request.user).exists():
            return Response({"detail": "forbidden"}, status=403)

        if booking.status not in ("pending", "confirmed"):
            return Response({"detail": "invalid status"}, status=400)

        if booking.paid:
            from payments.services import refund

            try:
                refund(booking)
            except Exception:
                return Response({"detail": "refund_failed"}, status=502)
            booking.status = "refunded"
        else:
            booking.status = "cancelled"
        booking.save(update_fields=["status"])
        return Response(BookingSerializer(booking).data)
