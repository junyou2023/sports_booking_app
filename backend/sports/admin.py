from django.contrib import admin
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
    UserActivityHistory,
)


@admin.register(Sport)
class SportAdmin(admin.ModelAdmin):
    list_display = ("name",)
    search_fields = ("name",)


@admin.register(Slot)
class SlotAdmin(admin.ModelAdmin):
    list_display = (
        "activity",
        "begins_at",
        "capacity",
        "current_participants",
        "price",
    )
    list_filter = ("activity", "begins_at")
    search_fields = ("activity__title", "location")
    autocomplete_fields = ("activity",)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "image_preview")
    search_fields = ("name",)
    readonly_fields = ("image_preview",)

    def image_preview(self, obj):
        if obj.image:
            from django.utils.html import format_html
            return format_html('<img src="{}" style="height:50px"/>', obj.image.url)
        return "-"


@admin.register(SportCategory)
class SportCategoryAdmin(admin.ModelAdmin):
    list_display = ("full_path", "parent")
    search_fields = ("name",)


@admin.register(Facility)
class FacilityAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "radius")
    search_fields = ("name", "owner__email")


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("user", "slot", "status", "paid", "pax", "booked_at")
    list_filter = ("slot__sport", "booked_at")
    autocomplete_fields = ("slot", "user")


@admin.register(Variant)
class VariantAdmin(admin.ModelAdmin):
    list_display = ("name", "discipline")
    list_filter = ("discipline",)
    search_fields = ("name",)


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ("title", "sport", "is_nearby")
    list_filter = ("sport", "is_nearby")
    search_fields = ("title",)
    readonly_fields = ("image_preview",)

    def image_preview(self, obj):
        if obj.image:
            from django.utils.html import format_html
            return format_html('<img src="{}" style="height:60px"/>', obj.image.url)
        return "-"


@admin.register(FeaturedCategory)
class FeaturedCategoryAdmin(admin.ModelAdmin):
    list_display = ("category", "order")
    list_editable = ("order",)


@admin.register(FeaturedActivity)
class FeaturedActivityAdmin(admin.ModelAdmin):
    list_display = ("activity", "order")
    list_editable = ("order",)


@admin.register(UserActivityHistory)
class UserActivityHistoryAdmin(admin.ModelAdmin):
    list_display = ("user", "activity", "action", "timestamp")
    list_filter = ("action",)
