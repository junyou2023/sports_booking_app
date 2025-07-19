# sports/models.py
# Domain models for the sports-booking backend.  Comments in EN only.

from django.db import models
from django.utils import timezone
from django.core.validators import (
    MinValueValidator,
    MaxValueValidator,
)
from django.contrib.gis.db import models as gis_models
from django.contrib.postgres.indexes import GistIndex


# ───────────────────────────────── Sport ──────────────────────────────────
class Sport(models.Model):
    name = models.CharField(max_length=30, unique=True)
    banner = models.URLField(blank=True)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:                # pragma: no cover
        return self.name


# ───────────────────────────────── Category ───────────────────────────────
class Category(models.Model):
    name = models.CharField(max_length=30, unique=True)
    icon = models.CharField(max_length=100, blank=True)

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:  # pragma: no cover
        return self.name


# ───────────────────────────────── Facility ───────────────────────────────
class Facility(models.Model):
    name = models.CharField(max_length=100)
    location = gis_models.PointField()
    categories = models.ManyToManyField(Category, related_name="facilities")
    radius = models.PositiveIntegerField(default=1000)

    class Meta:
        indexes = [
            GistIndex(fields=["location"]),
        ]

    def __str__(self) -> str:  # pragma: no cover
        return self.name


# ───────────────────────────────── Slot ───────────────────────────────────
class Slot(models.Model):
    """A single bookable time-window for one sport."""

    facility = models.ForeignKey(
        Facility,
        related_name="slots",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    sport = models.ForeignKey(
        Sport,
        related_name="slots",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    title = models.CharField(max_length=60)
    location = models.CharField(max_length=80)
    begins_at = models.DateTimeField()
    ends_at = models.DateTimeField()

    capacity = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1)]
    )
    price = models.DecimalField(  # 0.00 ⇒ free
        max_digits=7, decimal_places=2, default=0
    )
    rating = models.DecimalField(  # NEW: matches serializer / seed
        max_digits=3, decimal_places=1, default=0,
        help_text="Average rating 0–5"
    )

    class Meta:
        ordering = ("begins_at",)
        unique_together = ("facility", "begins_at")

    @property
    def seats_left(self) -> int:
        booked = self.bookings.aggregate(models.Sum("pax"))["pax__sum"] or 0
        return max(self.capacity - booked, 0)

    def __str__(self) -> str:                # pragma: no cover
        return f"{self.title} @ {self.begins_at:%Y-%m-%d %H:%M}"


# ──────────────────────────────── Booking ─────────────────────────────────
class Booking(models.Model):
    """User reservation of a slot (unique per user+slot)."""

    slot = models.ForeignKey(
        Slot, related_name="bookings", on_delete=models.PROTECT
    )
    user = models.ForeignKey("auth.User", on_delete=models.CASCADE)
    booked_at = models.DateTimeField(default=timezone.now)
    pax = models.PositiveSmallIntegerField(
        default=1,
        validators=[MinValueValidator(1), MaxValueValidator(20)],
        help_text="Number of people booked",
    )

    class Meta:
        ordering = ("-booked_at",)
        unique_together = ("slot", "user")

    def __str__(self) -> str:                # pragma: no cover
        return f"{self.user} → {self.slot} ({self.pax})"
