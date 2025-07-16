from django.contrib import admin
from .models import Sport, Slot, Booking, Category, Facility


@admin.register(Sport)
class SportAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(Slot)
class SlotAdmin(admin.ModelAdmin):
    list_display = ("title", "facility", "begins_at", "capacity", "price")
    list_filter = ("facility", "begins_at")
    search_fields = ("title", "location")


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(Facility)
class FacilityAdmin(admin.ModelAdmin):
    list_display = ("name", "radius")
    search_fields = ("name",)


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("user", "slot", "pax", "booked_at")
    list_filter = ("slot__sport", "booked_at")
    autocomplete_fields = ("slot", "user")
