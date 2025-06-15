from django.db import transaction
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response

from . import serializers
from .models import Sport, Slot, Booking
from .serializers import SportSerializer, SlotSerializer, BookingSerializer


class SportViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/sports/  and  /api/sports/{id}/
    """
    queryset = Sport.objects.all()
    serializer_class = SportSerializer
    permission_classes = [permissions.AllowAny]


class SlotViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/slots/  — returns all upcoming slots.
    """
    queryset = Slot.objects.select_related("sport")
    serializer_class = SlotSerializer
    permission_classes = [permissions.AllowAny]


class BookingViewSet(viewsets.ModelViewSet):
    """
    POST /api/bookings/  — create reservation
    GET  /api/bookings/  — list current user's reservations
    """
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Booking.objects
            .filter(user=self.request.user)
            .select_related("slot", "slot__sport")
        )

    def perform_create(self, serializer):
        slot = serializer.validated_data["slot"]

        # Atomic row-level lock to prevent over-booking
        with transaction.atomic():
            slot = (
                Slot.objects
                .select_for_update()
                .get(pk=slot.pk)
            )
            if slot.booked >= slot.capacity:
                raise serializers.ValidationError("Slot is fully booked.")

            slot.booked += 1
            slot.save(update_fields=["booked"])

            serializer.save(user=self.request.user, status=Booking.PENDING)
