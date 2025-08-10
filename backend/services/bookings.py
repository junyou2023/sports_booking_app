from django.utils import timezone
from sports.models import Booking


def cancel_expired_pending_bookings(minutes: int = 30) -> int:
    """Cancel pending bookings older than ``minutes`` minutes.

    Returns the number of bookings updated.
    """
    cutoff = timezone.now() - timezone.timedelta(minutes=minutes)
    qs = Booking.objects.filter(status="pending", booked_at__lt=cutoff)
    return qs.update(status="cancelled")
