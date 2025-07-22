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
from django.db.models import UniqueConstraint


# ───────────────────────────────── Sport ──────────────────────────────────
class Sport(models.Model):
    name = models.CharField(max_length=30, unique=True)
    banner = models.URLField(blank=True)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:                # pragma: no cover
        return self.name


# ──────────────────────────────── SportCategory ──────────────────────────────
class SportCategory(models.Model):
    """Hierarchical category tree used for activity discovery."""

    name = models.CharField(max_length=60)
    parent = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        related_name="children",
        on_delete=models.CASCADE,
    )

    class Meta:
        ordering = ("name",)
        constraints = [UniqueConstraint(fields=["parent", "name"], name="uniq_cat_parent_name")]

    def __str__(self) -> str:  # pragma: no cover
        return self.full_path

    @property
    def full_path(self) -> str:
        parts = [self.name]
        p = self.parent
        while p is not None:
            parts.append(p.name)
            p = p.parent
        return " / ".join(reversed(parts))

# ───────────────────────────────── Category ───────────────────────────────
class Category(models.Model):
    name = models.CharField(max_length=30, unique=True)
    image = models.ImageField(upload_to="category/", blank=True)

    @property
    def icon(self) -> str:
        return self.image.name if self.image else ""

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:  # pragma: no cover
        return self.name


# ───────────────────────────────── Variant ────────────────────────────────
class Variant(models.Model):
    """Third level taxonomy under a Category/Discipline."""

    discipline = models.ForeignKey(
        Category, related_name="variants", on_delete=models.CASCADE
    )
    name = models.CharField(max_length=30)

    class Meta:
        ordering = ("name",)
        unique_together = ("discipline", "name")

    def __str__(self) -> str:  # pragma: no cover
        return self.name


# ───────────────────────────────── Activity ───────────────────────────────
class Activity(models.Model):
    """Activity offered by a provider."""

    sport = models.ForeignKey(
        Sport, related_name="activities", on_delete=models.CASCADE
    )
    discipline = models.ForeignKey(
        Category, related_name="activities", on_delete=models.CASCADE
    )
    variant = models.ForeignKey(
        Variant,
        related_name="activities",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    title = models.CharField(max_length=60)
    description = models.TextField(blank=True, max_length=500)
    difficulty = models.PositiveSmallIntegerField(
        default=1, validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    duration = models.PositiveIntegerField(help_text="Minutes", default=60)
    base_price = models.DecimalField(
        max_digits=7,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
    )
    image = models.ImageField(upload_to="activity/", blank=True)
    is_nearby = models.BooleanField(default=False)
    owner = models.ForeignKey(
        "auth.User",
        on_delete=models.CASCADE,
        related_name="activities",
        null=True,
        blank=True,
    )

    class Meta:
        ordering = ("sport", "discipline", "title")

    def __str__(self) -> str:  # pragma: no cover
        return self.title


# ───────────────────────────────── Facility ───────────────────────────────
class Facility(models.Model):
    name = models.CharField(max_length=100)
    location = gis_models.PointField()
    categories = models.ManyToManyField(Category, related_name="facilities")
    radius = models.PositiveIntegerField(default=1000)
    owner = models.ForeignKey(
        "auth.User",
        on_delete=models.CASCADE,
        related_name="facilities",
        null=True,
        blank=True,
    )

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
    activity = models.ForeignKey(
        "Activity",
        related_name="slots",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    current_participants = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("begins_at",)
        unique_together = ("facility", "begins_at")

    @property
    def seats_left(self) -> int:
        return max(self.capacity - self.current_participants, 0)

    def __str__(self) -> str:                # pragma: no cover
        return f"{self.title} @ {self.begins_at:%Y-%m-%d %H:%M}"


# ──────────────────────────────── Booking ─────────────────────────────────
class Booking(models.Model):
    """User reservation of a slot (unique per user+slot)."""

    slot = models.ForeignKey(
        Slot, related_name="bookings", on_delete=models.PROTECT
    )
    activity = models.ForeignKey(
        "Activity",
        related_name="bookings",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    user = models.ForeignKey("auth.User", on_delete=models.CASCADE)
    booked_at = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, default="confirmed")
    paid = models.BooleanField(default=False)
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


# ————————— Homepage content —————————
class FeaturedCategory(models.Model):
    """Category showcased on the home page."""

    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    image = models.ImageField(upload_to="home_categories/")
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ("order",)

    def __str__(self) -> str:  # pragma: no cover
        return self.category.name


class FeaturedActivity(models.Model):
    """Activity highlighted on the home page carousel."""

    activity = models.ForeignKey(Activity, on_delete=models.CASCADE)
    image = models.ImageField(upload_to="home_activities/")
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ("order",)

    def __str__(self) -> str:  # pragma: no cover
        return self.activity.title


class Review(models.Model):
    activity = models.ForeignKey(
        Activity,
        related_name="reviews",
        on_delete=models.CASCADE,
    )
    user = models.ForeignKey("auth.User", on_delete=models.CASCADE)
    rating = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self) -> str:  # pragma: no cover
        return f"{self.user} → {self.activity} ({self.rating})"
