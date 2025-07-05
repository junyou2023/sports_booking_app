from django.contrib import admin
from .models import Sport, Slot, Booking


@admin.register(Sport)
class SportAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(Slot)
class SlotAdmin(admin.ModelAdmin):
    list_display = ("title", "sport", "begins_at", "capacity", "price")
    list_filter = ("sport", "begins_at")
    search_fields = ("title", "location")


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("user", "slot", "pax", "booked_at")
    list_filter = ("slot__sport", "booked_at")
    autocomplete_fields = ("slot", "user")
