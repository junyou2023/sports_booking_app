# sports/views.py
from django.db import models, transaction
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from .models import Sport, Slot, Booking, Category, Facility
from .serializers import (
    SportSerializer,
    SlotSerializer,
    BookingSerializer,
    CategorySerializer,
    FacilitySerializer,
)

from .models import Sport, Slot, Booking
from .serializers import SportSerializer, SlotSerializer, BookingSerializer


class SportViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Sport.objects.all()
    serializer_class = SportSerializer
    permission_classes = [permissions.AllowAny]


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]


class FacilityViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = FacilitySerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = Facility.objects.prefetch_related("categories")
        categories = self.request.query_params.get("categories")
        if categories:
            names = categories.split(",")
            qs = qs.filter(categories__name__in=names).distinct()

        near = self.request.query_params.get("near")
        if near:
            try:
                lat, lng = map(float, near.split(","))
                radius = float(self.request.query_params.get("radius", 5000))
                point = Point(lng, lat, srid=4326)
                qs = qs.filter(location__distance_lte=(point, radius)).annotate(
                    distance=Distance("location", point)
                ).order_by("distance")
            except ValueError:
                pass
        return qs


class SlotViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SlotSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = Slot.objects.select_related("facility")
        facility_id = self.request.query_params.get("facility_id")
        return qs.filter(facility_id=facility_id) if facility_id else qs


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user).select_related(
            "slot",
            "slot__facility",
        )

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)

        slot: Slot = ser.validated_data["slot"]
        pax = ser.validated_data["pax"]

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
