from django.urls import reverse
from rest_framework.test import APIClient
from backend.sports.models import Sport, Slot, Booking
from django.contrib.auth.models import User
from django.utils import timezone
import pytest


@pytest.mark.django_db
def test_sports_list(sport):
    client = APIClient()
    resp = client.get("/api/sports/")
    assert resp.status_code == 200
    assert resp.json()[0]["id"] == sport.id


@pytest.mark.django_db
def test_slots_filter(sport, slot):
    client = APIClient()
    resp = client.get("/api/slots/", {"sport": sport.id})
    assert resp.status_code == 200
    assert resp.json()[0]["id"] == slot.id


@pytest.mark.django_db
def test_my_slots_list(user, sport):
    slot = Slot.objects.create(
        sport=sport,
        title="Evening",
        location="Court 2",
        begins_at=timezone.now() + timezone.timedelta(hours=3),
        ends_at=timezone.now() + timezone.timedelta(hours=4),
        capacity=3,
        owner=user,
    )
    client = APIClient()
    client.force_authenticate(user=user)
    resp = client.get("/api/my-slots/")
    assert resp.status_code == 200
    assert resp.json()[0]["id"] == slot.id


@pytest.mark.django_db
def test_merchant_cannot_book_own_slot(user, sport):
    slot = Slot.objects.create(
        sport=sport,
        title="Night",
        location="Court 3",
        begins_at=timezone.now() + timezone.timedelta(hours=5),
        ends_at=timezone.now() + timezone.timedelta(hours=6),
        capacity=2,
        owner=user,
    )
    client = APIClient()
    client.force_authenticate(user=user)
    resp = client.post(
        "/api/bookings/",
        {"slot_id": slot.id, "pax": 1},
    )
    assert resp.status_code == 400
    assert resp.json()["detail"] == "Cannot book your own slot"


