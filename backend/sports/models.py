from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Sport(models.Model):
    """
    Sport category (badminton, sailing, …).
    """
    name = models.CharField(max_length=32, unique=True)
    banner = models.URLField(blank=True)           # hero/banner image
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["id"]

    def __str__(self) -> str:
        return self.name


class Slot(models.Model):
    """
    Bookable time block published by a vendor.
    """
    sport = models.ForeignKey(Sport, on_delete=models.CASCADE)
    start_at = models.DateTimeField()
    end_at = models.DateTimeField()
    capacity = models.PositiveSmallIntegerField(default=1)
    booked = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["start_at"]
        unique_together = ("sport", "start_at", "end_at")

    def __str__(self) -> str:
        return f"{self.sport.name} — {self.start_at:%Y-%m-%d %H:%M}"


class Booking(models.Model):
    """
    User reservation (state machine: pending → confirmed / canceled).
    """
    PENDING = "P"
    CONFIRMED = "C"
    CANCELED = "X"

    STATUS_CHOICES = [
        (PENDING, "Pending"),
        (CONFIRMED, "Confirmed"),
        (CANCELED, "Canceled"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    slot = models.ForeignKey(Slot, on_delete=models.PROTECT)
    status = models.CharField(max_length=1, choices=STATUS_CHOICES, default=PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = ("user", "slot")

    def __str__(self) -> str:
        return f"{self.user} · {self.slot} · {self.get_status_display()}"
