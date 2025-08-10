from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from django.db.models import F

from sports.models import Booking


class Command(BaseCommand):
    help = "Cancel pending bookings older than 30 minutes"

    def handle(self, *args, **options):
        cutoff = timezone.now() - timedelta(minutes=30)
        qs = Booking.objects.filter(
            status=Booking.STATUS_PENDING, booked_at__lt=cutoff
        ).select_related("slot")
        count = 0
        for b in qs:
            b.slot.current_participants = F("current_participants") - b.pax
            b.slot.save(update_fields=["current_participants"])
            b.status = Booking.STATUS_CANCELLED
            b.save(update_fields=["status"])
            count += 1
        self.stdout.write(f"Cancelled {count} bookings")
