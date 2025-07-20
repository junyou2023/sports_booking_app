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

    class Meta:
        model = Slot
        fields = "__all__"


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "icon")


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
    class Meta:
        model = Activity
        fields = (
            "id",
            "sport",
            "discipline",
            "variant",
            "image",
            "owner",
            "title",
            "description",
            "difficulty",
            "duration",
            "base_price",
        )
        read_only_fields = ("id", "owner")

    def validate_base_price(self, value):
        if value < 0:
            raise serializers.ValidationError("Must be >= 0")
        return value

    def validate(self, attrs):
        variant = attrs.get("variant")
        discipline = attrs.get("discipline")
        if variant and discipline and variant.discipline_id != discipline.id:
            raise serializers.ValidationError(
                {"variant": "Mismatch discipline"}
            )
        title = attrs.get("title", "")
        if len(title) > 60:
            raise serializers.ValidationError({"title": "Max 60 characters"})
        desc = attrs.get("description", "")
        if len(desc) > 500:
            raise serializers.ValidationError(
                {"description": "Max 500 characters"}
            )
        return attrs


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

    class Meta:
        model = Booking
        fields = ("id", "slot", "slot_id", "pax", "booked_at")
        read_only_fields = ("id", "booked_at")
