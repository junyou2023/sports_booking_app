"""
Very light smoke-tests proving that all endpoints work.
Run:  pytest backend
"""
import pytest
import django
django.setup()
from django.urls import reverse
from rest_framework.test import APIClient
from sports.models import Sport, Slot, Booking
from django.contrib.auth.models import User
from django.utils import timezone


pytestmark = pytest.mark.django_db


def test_sports_list():
    Sport.objects.create(name="Tennis1")
    client = APIClient()
    response = client.get("/api/sports/")
    assert response.status_code == 200


def test_slots_filter():
    sport = Sport.objects.create(name="Biking1")
    Slot.objects.create(
        sport=sport,
        title="Morning Ride",
        location="Park",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=10,
        price=0,
        rating=4.5,
    )
    client = APIClient()
    response = client.get("/api/slots/", {"sport": sport.id})
    assert response.status_code == 200
    for slot in response.data:
        assert slot["sport"] == sport.id


def test_booking_creation():
    user = User.objects.create_user("demo_api", password="demo123")
    sport = Sport.objects.create(name="Kayak1")
    slot = Slot.objects.create(
        sport=sport,
        title="Evening Ride",
        location="Lake",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
        price=10,
        rating=4.0,
    )
    client = APIClient()
    client.force_authenticate(user)
    response = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 2})
    assert response.status_code == 201
    assert Booking.objects.filter(user=user, slot=slot).exists()
