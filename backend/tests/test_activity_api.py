import django
django.setup()  # noqa: E402
import pytest  # noqa: E402
from rest_framework.test import APIClient  # noqa: E402
from sports.models import (  # noqa: E402
    Sport,
    Category,
    Variant,
    Facility,
    Slot,
)
from django.utils import timezone  # noqa: E402

pytestmark = [pytest.mark.django_db]


def setup_taxonomy():
    sport = Sport.objects.create(name="Surfing")
    disc = Category.objects.create(name="Wave Riding")
    var = Variant.objects.create(discipline=disc, name="Longboard")
    return sport, disc, var


def test_create_activity_invalid_taxonomy(auth_client):
    sport, disc, var = setup_taxonomy()
    resp = auth_client.post(
        "/api/activities/",
        {
            "sport": sport.id,
            "discipline": disc.id + 1,
            "variant": var.id,
            "title": "Surf 101",
        },
    )
    assert resp.status_code == 400


def test_create_activity_success(auth_client):
    sport, disc, var = setup_taxonomy()
    resp = auth_client.post(
        "/api/activities/",
        {
            "sport": sport.id,
            "discipline": disc.id,
            "variant": var.id,
            "title": "Surf 101",
            "difficulty": 3,
            "duration": 90,
            "base_price": "20.00",
        },
    )
    assert resp.status_code == 201
    assert resp.data["title"] == "Surf 101"


def test_bulk_slot_create(auth_client):
    sport, disc, var = setup_taxonomy()
    from django.contrib.gis.geos import Point
    facility = Facility.objects.create(name="Beach", location=Point(0, 0))
    Slot.objects.all().delete()
    resp = auth_client.post(
        "/api/slots/bulk/",
        {
            "facility": facility.id,
            "sport": sport.id,
            "start_time": timezone.now().isoformat(),
            "end_time": (
                timezone.now() + timezone.timedelta(hours=2)
            ).isoformat(),
            "interval": 60,
        },
    )
    assert resp.status_code == 201
    assert resp.data["created"] >= 1
    assert Slot.objects.count() == resp.data["created"]
