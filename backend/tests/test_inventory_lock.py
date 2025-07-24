import django
import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from django.contrib.auth.models import User
from sports.models import Sport, Slot, Booking, Activity, Category

django.setup()
pytestmark = pytest.mark.django_db


def test_double_booking_same_user_concurrent():
    user = User.objects.create_user("double")
    sport = Sport.objects.create(name="LockSport")
    activity = Activity.objects.create(sport=sport, discipline=Category.objects.create(name="Cat"), title="Act", status="published")
    slot = Slot.objects.create(
        sport=sport,
        activity=activity,
        title="Session",
        location="Arena",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=2,
        price=0,
        rating=0,
    )

    c = APIClient()
    c.force_authenticate(user)
    res1 = c.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    res2 = c.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})

    assert sorted([res1.status_code, res2.status_code]) == [201, 400]
    assert Booking.objects.filter(user=user, slot=slot).count() == 1

