# sports/serializers.py
from rest_framework import serializers
from .models import Sport, Slot, Booking


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


class BookingSerializer(serializers.ModelSerializer):
    slot = SlotSerializer(read_only=True)
    slot_id = serializers.PrimaryKeyRelatedField(
        queryset=Slot.objects.all(), write_only=True, source="slot"
    )

    class Meta:
        model = Booking
        fields = ("id", "slot", "slot_id", "pax", "booked_at")
        read_only_fields = ("id", "booked_at")
