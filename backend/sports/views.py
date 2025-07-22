# sports/views.py
from django.db import models, transaction
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from rest_framework import viewsets, permissions, status, serializers
from accounts.permissions import IsVendor
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone

from .models import (
    Sport,
    Review,
    Slot,
    Booking,
    Category,
    Facility,
    Variant,
    Activity,
    SportCategory,
    FeaturedCategory,
    FeaturedActivity,
)
from .serializers import (
    SportSerializer,
    SlotSerializer,
    BookingSerializer,
    CategorySerializer,
    FacilitySerializer,
    FacilityCreateSerializer,
    VariantSerializer,
    ActivitySerializer,
    SportCategorySerializer,
    FeaturedCategorySerializer,
    FeaturedActivitySerializer,
    ReviewSerializer,
    SlotCreateSerializer,
)


class SportViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Sport.objects.all()
    serializer_class = SportSerializer
    permission_classes = [permissions.AllowAny]


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]


class FeaturedCategoryViewSet(viewsets.ModelViewSet):
    queryset = FeaturedCategory.objects.select_related("category")
    serializer_class = FeaturedCategorySerializer

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny]


class FeaturedActivityViewSet(viewsets.ModelViewSet):
    queryset = FeaturedActivity.objects.select_related("activity")
    serializer_class = FeaturedActivitySerializer

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny]


class SportCategoryViewSet(viewsets.ModelViewSet):
    serializer_class = SportCategorySerializer

    def get_queryset(self):
        qs = SportCategory.objects.select_related("parent")
        return qs.order_by("parent_id", "name")

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticatedOrReadOnly()]

    def perform_create(self, serializer):
        parent = serializer.validated_data.get("parent")
        name = serializer.validated_data.get("name")
        if SportCategory.objects.filter(parent=parent, name=name).exists():
            raise serializers.ValidationError({"name": "Name exists"})
        serializer.save()

    def perform_update(self, serializer):
        parent = serializer.validated_data.get("parent")
        name = serializer.validated_data.get("name")
        if SportCategory.objects.filter(parent=parent, name=name).exclude(pk=serializer.instance.pk).exists():
            raise serializers.ValidationError({"name": "Name exists"})
        serializer.save()



class VariantViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Variant.objects.select_related("discipline")
    serializer_class = VariantSerializer
    permission_classes = [permissions.AllowAny]


class ActivityViewSet(viewsets.ModelViewSet):
    serializer_class = ActivitySerializer
    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            perms = [permissions.IsAuthenticated, IsVendor]
        else:
            perms = [permissions.AllowAny]
        return [p() if isinstance(p, type) else p for p in perms]

    def get_queryset(self):
        qs = Activity.objects.select_related("sport", "discipline", "variant")
        mine = self.request.query_params.get("mine")
        if mine == "1" and self.request.user.is_authenticated:
            qs = qs.filter(owner=self.request.user)
        nearby = self.request.query_params.get("nearby")
        if nearby == "1":
            qs = qs.filter(is_nearby=True)
        return qs

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class FacilityViewSet(viewsets.ModelViewSet):
    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            perms = [permissions.IsAuthenticated, IsVendor]
        else:
            perms = [permissions.IsAuthenticatedOrReadOnly]
        return [p() if isinstance(p, type) else p for p in perms]

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return FacilityCreateSerializer
        return FacilitySerializer

    def get_queryset(self):
        qs = Facility.objects.prefetch_related("categories")
        mine = self.request.query_params.get("mine")
        if mine == "1" and self.request.user.is_authenticated:
            qs = qs.filter(owner=self.request.user)
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
                qs = (
                    qs.filter(location__distance_lte=(point, radius))
                    .annotate(distance=Distance("location", point))
                    .order_by("distance")
                )
            except ValueError:
                pass
        return qs

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class SlotViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SlotSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = Slot.objects.select_related("facility", "sport", "activity")
        facility_id = self.request.query_params.get("facility_id")
        if facility_id:
            qs = qs.filter(facility_id=facility_id)
        sport_id = self.request.query_params.get("sport")
        if sport_id:
            qs = qs.filter(sport_id=sport_id)
        activity_id = self.request.query_params.get("activity")
        if activity_id:
            qs = qs.filter(activity_id=activity_id)
        date_str = self.request.query_params.get("date")
        if date_str:
            try:
                day = timezone.datetime.fromisoformat(date_str).date()
                qs = qs.filter(begins_at__date=day)
            except ValueError:
                pass
        return qs


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
        if slot.current_participants + pax > slot.capacity:
            return Response(
                {"detail": "Not enough seats left"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        booking = Booking.objects.create(
            slot=slot,
            activity=slot.activity,
            user=request.user,
            pax=pax,
            status="confirmed",
            paid=True,
        )
        slot.current_participants += pax
        slot.save(update_fields=["current_participants"])
        return Response(
            self.get_serializer(booking).data,
            status=status.HTTP_201_CREATED,
        )

class ActivityReviewList(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, activity_id):
        limit = request.query_params.get("limit")
        qs = Review.objects.filter(activity_id=activity_id).select_related("user").order_by("-created_at")
        if limit:
            try:
                qs = qs[: int(limit)]
            except ValueError:
                pass
        ser = ReviewSerializer(qs, many=True)
        return Response(ser.data)

    def post(self, request, activity_id):
        if not request.user.is_authenticated:
            return Response({"detail": "Authentication required"}, status=403)
        ser = ReviewSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        ser.save(activity_id=activity_id, user=request.user)
        return Response(ser.data, status=201)


class BulkSlotCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            facility = Facility.objects.get(pk=request.data.get("facility"))
            sport = Sport.objects.get(pk=request.data.get("sport"))
            start = timezone.datetime.fromisoformat(
                request.data.get("start_time")
            )
            end = timezone.datetime.fromisoformat(
                request.data.get("end_time")
            )
            interval = int(request.data.get("interval"))
        except Exception:
            return Response({"detail": "Invalid parameters"}, status=400)

        slots = []
        current = start
        while current + timezone.timedelta(minutes=interval) <= end:
            slots.append(
                Slot(
                    facility=facility,
                    sport=sport,
                    title=f"{sport.name} {current:%H:%M}",
                    location=facility.name,
                    begins_at=current,
                    ends_at=current
                    + timezone.timedelta(minutes=interval),
                    capacity=request.data.get("capacity", 1),
                    price=request.data.get("price", 0),
                )
            )
            current += timezone.timedelta(minutes=interval)
        Slot.objects.bulk_create(slots)
        return Response({"created": len(slots)}, status=201)


class MerchantSlotCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    def post(self, request):
        ser = SlotCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        activity: Activity = ser.validated_data["activity"]
        if activity.owner != request.user:
            return Response({"detail": "Not your activity"}, status=403)
        slot = ser.save()
        return Response(SlotSerializer(slot).data, status=201)


class MerchantBookingList(APIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    def get(self, request):
        qs = Booking.objects.filter(activity__owner=request.user).select_related(
            "slot", "user"
        )
        ser = BookingSerializer(qs, many=True)
        return Response(ser.data)
