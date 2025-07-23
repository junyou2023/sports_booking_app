import django
import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot
from django.contrib.auth.models import User

django.setup()
pytestmark = pytest.mark.django_db


def setup_taxonomy():
    sport = Sport.objects.create(name="Golf")
    cat = Category.objects.create(name="Outdoor")
    return sport, cat


def create_vendor():
    return User.objects.create_user("vendor", password="pass")


def test_publish_requires_future_slot():
    sport, cat = setup_taxonomy()
    vendor = create_vendor()
    client = APIClient()
    client.force_authenticate(vendor)
    resp = client.post(
        "/api/activities/",
        {"sport": sport.id, "discipline": cat.id, "title": "G101"},
    )
    act_id = resp.data["id"]
    publish = client.post(f"/api/activities/{act_id}/publish/")
    assert publish.status_code == 400


def test_publish_success():
    sport, cat = setup_taxonomy()
    vendor = create_vendor()
    client = APIClient()
    client.force_authenticate(vendor)
    resp = client.post(
        "/api/activities/",
        {"sport": sport.id, "discipline": cat.id, "title": "G102"},
    )
    act_id = resp.data["id"]
    activity = Activity.objects.get(pk=act_id)
    Slot.objects.create(
        activity=activity,
        sport=sport,
        title="Morning",
        location="Course",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=4,
        price=0,
    )
    publish = client.post(f"/api/activities/{act_id}/publish/")
    assert publish.status_code == 200
    activity.refresh_from_db()
    assert activity.status == Activity.STATUS_PUBLISHED
