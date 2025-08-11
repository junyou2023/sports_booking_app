from rest_framework import viewsets, permissions, generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.pagination import CursorPagination
from django.utils.dateparse import parse_datetime
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db.models import F, Q
from drf_spectacular.utils import extend_schema, OpenApiExample, OpenApiResponse, OpenApiParameter, OpenApiTypes

from .models import Slot, Booking
from .serializers import SlotSerializer, MerchantSlotSerializer, BookingSerializer
from accounts.permissions import IsVendor
from payments.services import refund


class MerchantSlotViewSet(viewsets.ModelViewSet):
    """CRUD operations for Slots owned by merchants."""

    permission_classes = [permissions.IsAuthenticated, IsVendor]

    def get_queryset(self):
        """Return slots belonging to the current vendor with optional filters."""
        user = self.request.user
        qs = Slot.objects.filter(activity__organization__members__user=user)

        params = self.request.query_params

        # active filter – default to active only
        active = params.get("active")
        if active in ("0", "false", "False"):
            qs = qs.filter(is_active=False)
        else:
            qs = qs.filter(is_active=True)

        activity_id = params.get("activity")
        if activity_id:
            qs = qs.filter(activity_id=activity_id)

        after = params.get("after")
        if after:
            dt = parse_datetime(after)
            if dt:
                qs = qs.filter(begins_at__gte=dt)

        before = params.get("before")
        if before:
            dt = parse_datetime(before)
            if dt:
                qs = qs.filter(begins_at__lte=dt)

        keyword = params.get("q")
        if keyword:
            qs = qs.filter(Q(title__icontains=keyword) | Q(location__icontains=keyword))

        ordering = params.get("ordering") or "-begins_at"
        if ordering not in ("begins_at", "-begins_at"):
            ordering = "-begins_at"
        return qs.order_by(ordering)

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return MerchantSlotSerializer
        return SlotSerializer

    @extend_schema(
        responses={201: SlotSerializer, 400: OpenApiResponse(description="Validation error")}
    )
    def create(self, request, *args, **kwargs):
        return super().create(request, *args, **kwargs)

    @extend_schema(
        responses={200: SlotSerializer, 400: OpenApiResponse(description="Validation error")}
    )
    def update(self, request, *args, **kwargs):
        return super().update(request, *args, **kwargs)

    @extend_schema(
        responses={200: SlotSerializer, 400: OpenApiResponse(description="Validation error")}
    )
    def partial_update(self, request, *args, **kwargs):
        return super().partial_update(request, *args, **kwargs)

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active"])


class MerchantSlotBulkDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    @extend_schema(
        request={
            "type": "object",
            "properties": {"ids": {"type": "array", "items": {"type": "integer"}}},
        },
        responses={
            200: OpenApiResponse(
                description="Bulk delete result",
                examples=[
                    OpenApiExample(
                        "Result", value={"deleted": 1, "forbidden": [], "not_found": []}
                    )
                ],
            )
        },
    )
    def delete(self, request):
        ids = request.data.get("ids", [])
        if not isinstance(ids, list):
            return Response({"ids": "Invalid"}, status=400)

        qs = Slot.objects.filter(id__in=ids)
        accessible = qs.filter(activity__organization__members__user=request.user)
        deleted = accessible.update(is_active=False)
        accessible_ids = set(accessible.values_list("id", flat=True))
        existing_ids = set(qs.values_list("id", flat=True))
        forbidden = list(existing_ids - accessible_ids)
        not_found = [i for i in ids if i not in existing_ids]
        return Response({
            "deleted": deleted,
            "forbidden": forbidden,
            "not_found": not_found,
        })

class BookingCursorPagination(CursorPagination):
    page_size = 50
    ordering = '-booked_at'


class MerchantBookingListPaged(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]
    serializer_class = BookingSerializer
    pagination_class = BookingCursorPagination

    def get_queryset(self):
        qs = Booking.objects.filter(
            activity__organization__members__user=self.request.user
        ).select_related("slot", "user", "slot__activity")
        params = self.request.query_params
        status_param = params.get("status")
        if status_param in dict(Booking.STATUS_CHOICES):
            qs = qs.filter(status=status_param)
        paid = params.get("paid")
        if paid == "true":
            qs = qs.filter(paid=True)
        elif paid == "false":
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
        return qs

    @extend_schema(
        parameters=[
            OpenApiParameter("status", OpenApiTypes.STR, required=False),
            OpenApiParameter("paid", OpenApiTypes.BOOL, required=False),
            OpenApiParameter("created_after", OpenApiTypes.DATETIME, required=False),
            OpenApiParameter("created_before", OpenApiTypes.DATETIME, required=False),
            OpenApiParameter("activity_id", OpenApiTypes.INT, required=False),
            OpenApiParameter("cursor", OpenApiTypes.STR, required=False),
        ],
        responses={
            200: OpenApiResponse(
                response=BookingSerializer(many=True),
                examples=[
                    OpenApiExample(
                        "Example",
                        value={"next": None, "previous": None, "results": []},
                    )
                ],
            )
        },
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)


class MerchantBookingCancelView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    @extend_schema(
        responses={
            200: BookingSerializer,
            400: OpenApiResponse(description="Invalid state"),
            502: OpenApiResponse(description="Refund failed"),
        }
    )
    def post(self, request, pk):
        booking = get_object_or_404(
            Booking.objects.select_related("slot"),
            pk=pk,
            activity__organization__members__user=request.user,
        )
        if booking.status not in (Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED):
            return Response({"detail": "invalid_status"}, status=400)
        if booking.paid:
            try:
                refund(booking)
            except Exception:
                return Response({"detail": "refund_failed"}, status=502)
            booking.status = Booking.STATUS_REFUNDED
        else:
            booking.status = Booking.STATUS_CANCELLED
        booking.save(update_fields=["status"])
        booking.slot.current_participants = F("current_participants") - booking.pax
        booking.slot.save(update_fields=["current_participants"])
        booking.slot.refresh_from_db()
        ser = BookingSerializer(booking)
        return Response(ser.data)
