from django.core.management.base import BaseCommand
from services.bookings import cancel_expired_pending_bookings


class Command(BaseCommand):
    help = "Cancel pending bookings older than 30 minutes"

    def handle(self, *args, **options):
        count = cancel_expired_pending_bookings()
        self.stdout.write(f"Cancelled {count} bookings")
