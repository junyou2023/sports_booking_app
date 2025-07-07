from django.urls import reverse
from rest_framework.test import APIClient
from backend.sports.models import Sport, Slot, Booking
from django.contrib.auth.models import User
import pytest


@pytest.mark.django_db
def test_sports_list(client, sport):
    resp = client.get("/api/sports/")
    assert resp.status_code == 200
    assert resp.json()[0]["id"] == sport.id


@pytest.mark.django_db
def test_slots_filter(client, sport, slot):
    resp = client.get("/api/slots/", {"sport": sport.id})
    assert resp.status_code == 200
    assert resp.json()[0]["id"] == slot.id


