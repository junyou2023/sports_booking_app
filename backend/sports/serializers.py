from rest_framework import serializers
from .models import Sport, Slot, Booking


class SportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sport
        fields = "__all__"


class SlotSerializer(serializers.ModelSerializer):
    sport = SportSerializer(read_only=True)

    class Meta:
        model = Slot
        fields = "__all__"


class BookingSerializer(serializers.ModelSerializer):
    slot = SlotSerializer(read_only=True)

    class Meta:
        model = Booking
        fields = "__all__"
        read_only_fields = ("user", "status")
