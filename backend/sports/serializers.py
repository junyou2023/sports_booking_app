# sports/serializers.py
from rest_framework import serializers
from rest_framework_gis.serializers import GeoFeatureModelSerializer
from django.contrib.gis.geos import Point
from .models import (
    Sport,
    Slot,
    Booking,
    Category,
    Facility,
    Variant,
    Activity,
    SportCategory,
    FeaturedCategory,
    Review,
    FeaturedActivity,
)


class SportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sport
        fields = ("id", "name", "banner", "description")


class SlotSerializer(serializers.ModelSerializer):
    price = serializers.DecimalField(
        max_digits=7, decimal_places=2, coerce_to_string=False
    )
    rating = serializers.DecimalField(
        max_digits=3, decimal_places=1, coerce_to_string=False
    )
    seats_left = serializers.SerializerMethodField()
    sport = SportSerializer(read_only=True)

    class Meta:
        model = Slot
        fields = "__all__"

    def get_seats_left(self, obj):
        return obj.seats_left

    def to_representation(self, instance):
        """Ensure sport is serialized even if missing on the Slot instance."""
        if instance.sport_id is None and instance.activity_id:
            instance.sport = instance.activity.sport
        return super().to_representation(instance)


class SlotCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Slot
        fields = (
            "activity",
            "begins_at",
            "ends_at",
            "capacity",
            "price",
            "title",
            "location",
        )

    def get_seats_left(self, obj):
        return obj.seats_left

    def create(self, validated_data):
        """Populate sport from the related activity when creating a Slot."""
        activity = validated_data["activity"]
        return Slot.objects.create(
            **validated_data,
            sport=activity.sport,
        )


class CategorySerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ("id", "name", "icon", "image_url")
        read_only_fields = ("icon",)

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get("request")
            url = obj.image.url
            return request.build_absolute_uri(url) if request else url
        return ""


class SportCategorySerializer(serializers.ModelSerializer):
    full_path = serializers.CharField(read_only=True)

    class Meta:
        model = SportCategory
        fields = ("id", "name", "parent", "full_path")


class VariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Variant
        fields = ("id", "discipline", "name")


class ActivitySerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Activity
        fields = (
            "id",
            "sport",
            "discipline",
            "variant",
            "image",
            "image_url",
            "owner",
            "title",
            "description",
            "difficulty",
            "duration",
            "base_price",
            "is_nearby",
        )
        read_only_fields = ("id", "owner", "image")

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get("request")
            url = obj.image.url
            return request.build_absolute_uri(url) if request else url
        return ""

    def validate_base_price(self, value):
        if value < 0:
            raise serializers.ValidationError("Must be >= 0")
        return value

    def validate(self, attrs):
        variant = attrs.get("variant")
        discipline = attrs.get("discipline")
        if variant and discipline and variant.discipline_id != discipline.id:
            raise serializers.ValidationError({"variant": "Mismatch discipline"})
        title = attrs.get("title", "")
        if len(title) > 60:
            raise serializers.ValidationError({"title": "Max 60 characters"})
        desc = attrs.get("description", "")
        if len(desc) > 500:
            raise serializers.ValidationError({"description": "Max 500 characters"})
        return attrs


class ActivitySimpleSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Activity
        fields = ("id", "title", "image_url", "base_price")

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get("request")
            url = obj.image.url
            return request.build_absolute_uri(url) if request else url
        return ""


class FeaturedCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = FeaturedCategory
        fields = ("id", "category", "image", "order")


class FeaturedActivitySerializer(serializers.ModelSerializer):
    class Meta:
        model = FeaturedActivity
        fields = ("id", "activity", "image", "order")


class FacilitySerializer(GeoFeatureModelSerializer):
    owner = serializers.SerializerMethodField()

    class Meta:
        model = Facility
        geo_field = "location"
        fields = (
            "id",
            "name",
            "radius",
            "location",
            "categories",
            "owner",
        )

    def get_owner(self, obj):
        return getattr(obj.owner, "email", "")


class FacilityCreateSerializer(serializers.ModelSerializer):
    lat = serializers.FloatField(write_only=True)
    lng = serializers.FloatField(write_only=True)

    owner = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Facility
        fields = (
            "id",
            "name",
            "lat",
            "lng",
            "radius",
            "categories",
            "owner",
        )

    def get_owner(self, obj):
        return getattr(obj.owner, "email", "")

    def create(self, validated_data):
        lat = validated_data.pop("lat")
        lng = validated_data.pop("lng")
        point = Point(lng, lat, srid=4326)
        request = self.context.get("request")
        owner = request.user if request else None
        facility = Facility.objects.create(
            location=point, owner=owner, **validated_data
        )
        return facility


class BookingSerializer(serializers.ModelSerializer):
    slot = SlotSerializer(read_only=True)
    slot_id = serializers.PrimaryKeyRelatedField(
        queryset=Slot.objects.all(), write_only=True, source="slot"
    )
    status = serializers.CharField(read_only=True)
    paid = serializers.BooleanField(read_only=True)

    class Meta:
        model = Booking
        fields = (
            "id",
            "slot",
            "slot_id",
            "pax",
            "booked_at",
            "status",
            "paid",
        )
        read_only_fields = ("id", "booked_at", "status", "paid")


class ReviewSerializer(serializers.ModelSerializer):
    user_email = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ("id", "user_email", "rating", "comment", "created_at")

    def get_user_email(self, obj):
        return getattr(obj.user, "email", "")
