# sports/views.py
from django.db import models, transaction
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response

from .models      import Sport, Slot, Booking
from .serializers import SportSerializer, SlotSerializer, BookingSerializer


class SportViewSet(viewsets.ReadOnlyModelViewSet):
    queryset           = Sport.objects.all()
    serializer_class   = SportSerializer
    permission_classes = [permissions.AllowAny]


class SlotViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class   = SlotSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs       = Slot.objects.select_related("sport")
        sport_id = self.request.query_params.get("sport")
        return qs.filter(sport_id=sport_id) if sport_id else qs


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class   = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user).select_related(
            "slot", "slot__sport"
        )

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)

        slot: Slot = ser.validated_data["slot"]
        pax        = ser.validated_data["pax"]

        slot = Slot.objects.select_for_update().get(pk=slot.pk)
        taken = slot.bookings.aggregate(t=models.Sum("pax"))["t"] or 0
        if taken + pax > slot.capacity:
            return Response(
                {"detail": "Not enough seats left"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        booking = Booking.objects.create(slot=slot, user=request.user, pax=pax)
        return Response(
            self.get_serializer(booking).data,
            status=status.HTTP_201_CREATED,
        )
