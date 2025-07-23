import django
import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from django.contrib.auth.models import User
from sports.models import Sport, Slot, Booking

django.setup()
pytestmark = pytest.mark.django_db


def test_double_booking_same_user_concurrent():
    user = User.objects.create_user("double")
    sport = Sport.objects.create(name="LockSport")
    slot = Slot.objects.create(
        sport=sport,
        title="Session",
        location="Arena",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=2,
        price=0,
        rating=0,
    )

    results = []

    def book_once():
        c = APIClient()
        c.force_authenticate(user)
        res = c.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
        results.append(res.status_code)

    import threading

    t1 = threading.Thread(target=book_once)
    t2 = threading.Thread(target=book_once)
    t1.start(); t2.start(); t1.join(); t2.join()

    assert results.count(201) == 1
    assert Booking.objects.filter(user=user, slot=slot).count() == 1

