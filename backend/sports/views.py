# sports/views.py
from django.db import transaction
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance, Transform
from django.contrib.gis.measure import D
from django.db.models import Q, F, Value, Min, IntegerField
from django.db.models.functions import Cast
from django.conf import settings
from rest_framework import viewsets, permissions, status, serializers, mixins
from rest_framework.decorators import action
from accounts.permissions import IsVendor
from accounts.models import OrganizationMember, Organization
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.utils import timezone, dateparse
from drf_spectacular.utils import (
    extend_schema,
    OpenApiResponse,
    OpenApiExample,
    OpenApiParameter,
    OpenApiTypes,
)

from .models import (
    Sport,
    Review,
    Slot,
    Booking,
    Category,
    Facility,
    Variant,
    Activity,
    UserActivityHistory,
    SportCategory,
    FeaturedCategory,
    FeaturedActivity,
    Favorite,
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
    ActivitySimpleSerializer,
    SportCategorySerializer,
    FeaturedCategorySerializer,
    FeaturedActivitySerializer,
    ReviewSerializer,
    SlotCreateSerializer,
    FavoriteSerializer,
)


# ---------------------------------------------------------------------------
# Helpers for optional location-based filtering
# ---------------------------------------------------------------------------
def _parse_radius(value, default=settings.NEARBY_DEFAULT_RADIUS_M, lo=100, hi=30000):
    """Return a sanitized radius in meters."""
    try:
        v = int(value) if value is not None else default
        return max(lo, min(hi, v))
    except Exception:
        return default


def _apply_near_filter(qs, field_name, latlng, radius_m, aggregate=False):
    """Filter and annotate queryset by distance to a point.

    Returns (queryset, used) where used indicates whether the filter was
    applied. Any errors (invalid input or missing GIS stack) fall back to the
    unmodified queryset.
    """

    if not latlng:
        return qs, False
    try:
        lat, lng = [float(x) for x in latlng.split(",")]
        p4326 = Point(lng, lat, srid=4326)
        filter_kwargs = {f"{field_name}__distance_lte": (p4326, D(m=radius_m))}
        distance = Distance(
            Transform(F(field_name), 3857),
            Transform(Value(p4326), 3857),
        )
        if aggregate:
            distance = Min(distance)
        qs = (
            qs.filter(**filter_kwargs)
            .annotate(_distance_m=Cast(distance, IntegerField()))
            .order_by("_distance_m")
        )
        return qs, True
    except Exception:
        return qs, False


class DefaultPagination(PageNumberPagination):
    """Simple page-number pagination with 20 items per page."""

    page_size = 20
    page_size_query_param = "page_size"


class SportViewSet(viewsets.ModelViewSet):
    queryset = Sport.objects.all()
    serializer_class = SportSerializer

    def get_permissions(self):
        if self.action == "create":
            return [IsVendor()]
        if self.action in ("update", "partial_update", "destroy"):
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = DefaultPagination


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
        if (
            SportCategory.objects.filter(parent=parent, name=name)
            .exclude(pk=serializer.instance.pk)
            .exists()
        ):
            raise serializers.ValidationError({"name": "Name exists"})
        serializer.save()


class VariantViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Variant.objects.select_related("discipline")
    serializer_class = VariantSerializer
    permission_classes = [permissions.AllowAny]


class ActivityViewSet(viewsets.ModelViewSet):
    serializer_class = ActivitySerializer
    pagination_class = DefaultPagination

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            perms = [permissions.IsAuthenticated, IsVendor]
        else:
            perms = [permissions.AllowAny]
        return [p() if isinstance(p, type) else p for p in perms]

    def get_queryset(self):
        qs = Activity.objects.select_related("sport", "discipline", "variant", "organization")
        if self.action in ("update", "partial_update", "destroy"):
            qs = qs.filter(organization__members__user=self.request.user)
        mine = self.request.query_params.get("mine")
        if mine == "1" and self.request.user.is_authenticated:
            qs = qs.filter(organization__members__user=self.request.user)
        nearby = self.request.query_params.get("nearby")
        if nearby == "1":
            qs = qs.filter(is_nearby=True)
        else:
            near = self.request.query_params.get("near")
            radius = _parse_radius(self.request.query_params.get("radius"))
            qs, used = _apply_near_filter(
                qs, "slots__facility__location", near, radius, aggregate=True
            )
            if used:
                qs = qs.distinct()
        category = self.request.query_params.get("category")
        if category:
            try:
                qs = qs.filter(discipline_id=int(category))
            except (TypeError, ValueError):
                qs = qs.none()

        query = self.request.query_params.get("q")
        if query:
            query = query.strip()
            if len(query) > 64:
                return qs.none()
            qs = qs.filter(
                Q(title__icontains=query)
                | Q(description__icontains=query)
                | Q(sport__name__icontains=query)
                | Q(discipline__name__icontains=query)
            )

        return qs

    @extend_schema(
        parameters=[
            OpenApiParameter(
                name="near",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Distance search using facility location. Ignored if nearby=1.",
                examples=[OpenApiExample("Example", value="51.5072,-0.1276")],
            ),
            OpenApiParameter(
                name="radius",
                type=OpenApiTypes.INT,
                location=OpenApiParameter.QUERY,
                description="Search radius in meters (default 5000, min 100, max 30000)",
            ),
        ]
    )
    def list(self, request, *args, **kwargs):
        if request.query_params.get("no_page") == "1":
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response({"results": serializer.data})
        return super().list(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save()

    @action(detail=True, methods=["post"], url_path="favorite/toggle",
            permission_classes=[permissions.IsAuthenticated])
    def favorite_toggle(self, request, pk=None):
        fav, created = Favorite.objects.get_or_create(
            user=request.user, activity_id=pk
        )
        if not created:
            fav.delete()
            return Response({"favorited": False})
        return Response({"favorited": True})


class FacilityViewSet(viewsets.ModelViewSet):
    pagination_class = DefaultPagination
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

        query = self.request.query_params.get("q")
        if query:
            query = query.strip()
            if len(query) > 64:
                return qs.none()
            qs = qs.filter(
                Q(name__icontains=query) | Q(categories__name__icontains=query)
            ).distinct()
        near = self.request.query_params.get("near")
        radius = _parse_radius(self.request.query_params.get("radius"))
        qs, _ = _apply_near_filter(qs, "location", near, radius)
        return qs

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @extend_schema(
        parameters=[
            OpenApiParameter(
                name="near",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description='Filter by distance to "lat,lng"',
                examples=[OpenApiExample("Example", value="51.5072,-0.1276")],
            ),
            OpenApiParameter(
                name="radius",
                type=OpenApiTypes.INT,
                location=OpenApiParameter.QUERY,
                description="Search radius in meters (default 5000, min 100, max 30000)",
            ),
        ]
    )
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)


class SlotViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SlotSerializer
    permission_classes = [permissions.AllowAny]
    lookup_value_regex = r"\d+"
    pagination_class = DefaultPagination

    def get_queryset(self):
        qs = Slot.objects.select_related("facility", "sport", "activity")
        after = self.request.query_params.get("after")
        before = self.request.query_params.get("before")
        if not after and not before:
            after = timezone.now().isoformat()
        facility_id = self.request.query_params.get("facility_id")
        if facility_id:
            qs = qs.filter(facility_id=facility_id)
        sport_id = self.request.query_params.get("sport")
        if sport_id:
            qs = qs.filter(sport_id=sport_id)
        activity_id = self.request.query_params.get("activity")
        if activity_id:
            qs = qs.filter(activity_id=activity_id)
        if after:
            try:
                dt = timezone.datetime.fromisoformat(after)
                qs = qs.filter(begins_at__gte=dt)
            except ValueError:
                pass
        if before:
            try:
                dt = timezone.datetime.fromisoformat(before)
                qs = qs.filter(begins_at__lte=dt)
            except ValueError:
                pass
        return qs

    @action(
        detail=False,
        methods=["post"],
        url_path="bulk",
        permission_classes=[permissions.IsAuthenticated],
    )
    def bulk(self, request):
        start = dateparse.parse_datetime(request.data.get("start_time"))
        end = dateparse.parse_datetime(request.data.get("end_time"))
        interval = int(request.data.get("interval", 60))
        facility = Facility.objects.filter(id=request.data.get("facility")).first()
        activity = Activity.objects.filter(id=request.data.get("activity")).first()

        if not activity and request.data.get("sport"):
            sport = Sport.objects.get(id=request.data["sport"])
            org = Organization.objects.first() or Organization.objects.create(
                name="Org", slug="org"
            )
            disc = Category.objects.first() or Category.objects.create(name="Auto")
            activity = Activity.objects.create(
                sport=sport,
                discipline=disc,
                title="Auto",
                duration=60,
                base_price=0,
                organization=org,
            )

        created = []
        cur = start
        while cur and end and cur < end:
            s = Slot.objects.create(
                facility=facility,
                activity=activity,
                sport=activity.sport if activity else None,
                title="Bulk",
                location="",
                begins_at=cur,
                ends_at=cur + timezone.timedelta(minutes=interval),
                capacity=10,
                price=0,
            )
            created.append(s.id)
            cur += timezone.timedelta(minutes=interval)

        return Response({"created": created}, status=status.HTTP_201_CREATED)


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # BUG: selecting the facility loads GeoDjango PointField which requires
        # the GDAL/SpatiaLite stack. Missing libs caused the server to drop the
        # connection when listing bookings (My Bookings → "connection closed").
        # FIX: only join the Slot; facility id is enough for clients (covers:
        # My Bookings list).
        #
        # Also: hide unpaid/pending bookings so that opening a checkout session
        # without completing payment doesn't show up as an active booking.
        return (
            Booking.objects.filter(user=self.request.user, paid=True)
            .select_related("slot")
        )

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        ser = self.get_serializer(data=request.data)
        ser.is_valid(raise_exception=True)

        slot: Slot = ser.validated_data["slot"]
        pax = ser.validated_data["pax"]

        slot = Slot.objects.select_for_update().get(pk=slot.pk)
        if not slot.is_active:
            return Response({"detail": "Slot inactive"}, status=400)
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
            status="pending",
            paid=False,
            price=slot.price * pax,
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
        qs = (
            Review.objects.filter(activity_id=activity_id)
            .select_related("user")
            .order_by("-created_at")
        )
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


class ContinuePlanningView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        histories = (
            UserActivityHistory.objects.filter(user=user)
            .order_by("-timestamp")[:20]
        )
        act_ids = []
        for h in histories:
            if h.activity_id not in act_ids:
                act_ids.append(h.activity_id)

        unfinished = (
            Booking.objects.filter(user=user, paid=False)
            .values_list("activity_id", flat=True)
        )
        for aid in unfinished:
            if aid and aid not in act_ids:
                act_ids.append(aid)

        acts = {a.id: a for a in Activity.objects.filter(id__in=act_ids)}
        ordered = [acts[a] for a in act_ids if a in acts]
        ser = ActivitySimpleSerializer(
            ordered, many=True, context={"request": request}
        )
        return Response({"results": ser.data})


class BulkSlotCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        responses={
            201: OpenApiResponse(
                description="Slots created",
                examples=[OpenApiExample("Success", value={"created": 1})],
            ),
            400: OpenApiResponse(description="Invalid parameters"),
        }
    )
    def post(self, request):
        data = request.data
        errors = {}

        facility = Facility.objects.filter(pk=data.get("facility")).first()
        if not facility:
            errors["facility"] = "Invalid facility"
        sport = Sport.objects.filter(pk=data.get("sport")).first()
        if not sport:
            errors["sport"] = "Invalid sport"

        try:
            start = timezone.datetime.fromisoformat(data.get("start_time"))
        except Exception:
            start = None
            errors["start_time"] = "Invalid"
        try:
            end = timezone.datetime.fromisoformat(data.get("end_time"))
        except Exception:
            end = None
            errors["end_time"] = "Invalid"
        try:
            interval = int(data.get("interval"))
        except Exception:
            interval = None
            errors["interval"] = "Invalid"

        if errors:
            return Response(errors, status=400)

        slots = []
        current = start
        while current + timezone.timedelta(minutes=interval) <= end:
            slots.append(
                (
                    current,
                    current + timezone.timedelta(minutes=interval),
                )
            )
            current += timezone.timedelta(minutes=interval)

        now = timezone.now()
        conflicts = []
        for begins, ends in slots:
            if begins.date() != ends.date() or begins < now:
                return Response({"detail": "invalid_time"}, status=400)
            conflict = Slot.objects.filter(
                facility=facility,
                sport=sport,
                begins_at__lt=ends,
                ends_at__gt=begins,
                is_active=True,
            ).first()
            if conflict:
                conflicts.append(
                    {
                        "begins_at": begins.isoformat(),
                        "ends_at": ends.isoformat(),
                        "conflict_with_id": conflict.id,
                    }
                )
                if len(conflicts) >= 3:
                    break

        if conflicts:
            return Response({"detail": "conflict", "examples": conflicts}, status=400)

        objs = [
            Slot(
                facility=facility,
                sport=sport,
                title=f"{sport.name} {b:%H:%M}",
                location=facility.name,
                begins_at=b,
                ends_at=e,
                capacity=data.get("capacity", 1),
                price=data.get("price", 0),
            )
            for b, e in slots
        ]
        Slot.objects.bulk_create(objs)
        return Response({"created": len(objs)}, status=201)


class MerchantBookingList(APIView):
    permission_classes = [permissions.IsAuthenticated, IsVendor]

    def get(self, request):
        qs = Booking.objects.filter(
            activity__organization__members__user=request.user
        ).select_related("slot", "user")
        ser = BookingSerializer(qs, many=True)
        return Response(ser.data)


class FavoriteViewSet(viewsets.GenericViewSet,
                      mixins.ListModelMixin,
                      mixins.CreateModelMixin,
                      mixins.DestroyModelMixin):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FavoriteSerializer
    pagination_class = DefaultPagination

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user).select_related(
            "activity")

    def create(self, request, *args, **kwargs):
        activity_id = request.data.get("activity")
        if not activity_id:
            return Response({"detail": "activity required"}, status=400)
        fav, created = Favorite.objects.get_or_create(
            user=request.user, activity_id=activity_id
        )
        status_code = (
            status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )
        return Response({"favorited": True}, status=status_code)

    def destroy(self, request, pk=None):
        Favorite.objects.filter(user=request.user, activity_id=pk).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=["get"], pagination_class=None)
    def ids(self, request):
        ids = list(
            Favorite.objects.filter(user=request.user).values_list(
                "activity_id", flat=True
            )
        )
        return Response(ids)

    @action(detail=False, methods=["get"], pagination_class=None)
    def count(self, request):
        cnt = Favorite.objects.filter(user=request.user).count()
        return Response({"count": cnt})
