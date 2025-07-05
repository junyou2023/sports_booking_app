"""
Very light smoke-tests proving that all endpoints work.
Run:  pytest backend
"""
import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from sports.models import Sport, Slot, Booking
from django.contrib.auth.models import User


pytestmark = pytest.mark.django_db


def test_sports_list():
    client = APIClient()
    response = client.get("/api/sports/")
    assert response.status_code == 200


def test_slots_filter():
    sport = Sport.objects.first()
    client = APIClient()
    response = client.get("/api/slots/", {"sport": sport.id})
    assert response.status_code == 200
    for slot in response.data:
        assert slot["sport"]["id"] == sport.id


def test_booking_creation():
    user = User.objects.create_user("demo", password="demo123")
    slot = Slot.objects.first()
    client = APIClient()
    client.force_authenticate(user)
    response = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 2})
    assert response.status_code == 201
    assert Booking.objects.filter(user=user, slot=slot).exists()
