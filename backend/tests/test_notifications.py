import django
import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from sports.models import Slot, Sport, Booking, Notification
from django.utils import timezone

django.setup()

pytestmark = pytest.mark.django_db


def _create_booking(user):
    sport = Sport.objects.create(name="Pingpong")
    slot = Slot.objects.create(
        sport=sport,
        title="Match",
        location="Hall",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=2,
    )
    return Booking.objects.create(slot=slot, user=user)


def test_booking_creates_notification():
    user = User.objects.create_user("u1")
    _create_booking(user)
    assert Notification.objects.filter(user=user).count() == 1


def test_mark_all_read_endpoint():
    user = User.objects.create_user("u2")
    _create_booking(user)
    client = APIClient()
    client.force_authenticate(user)
    resp = client.get("/api/notifications/unread_count/")
    assert resp.data["count"] == 1
    client.post("/api/notifications/mark_all_read/")
    resp = client.get("/api/notifications/unread_count/")
    assert resp.data["count"] == 0


def test_notifications_auth_required(client):
    resp = client.get("/api/notifications/")
    assert resp.status_code == 401

