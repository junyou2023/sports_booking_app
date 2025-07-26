import django
import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot

django.setup()
pytestmark = pytest.mark.django_db


def test_slots_filter_by_activity_and_after_utc():
    sport = Sport.objects.create(name="Ping")
    cat = Category.objects.create(name="Gen")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="A",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
    )
    before = timezone.now() + timezone.timedelta(hours=1)
    after = before + timezone.timedelta(hours=2)
    Slot.objects.create(
        sport=sport,
        activity=act,
        title="B1",
        location="L",
        begins_at=before,
        ends_at=before + timezone.timedelta(hours=1),
        capacity=5,
        price=0,
        rating=0,
    )
    later_slot = Slot.objects.create(
        sport=sport,
        activity=act,
        title="B2",
        location="L2",
        begins_at=after,
        ends_at=after + timezone.timedelta(hours=1),
        capacity=5,
        price=0,
        rating=0,
    )
    client = APIClient()
    ts = (before + timezone.timedelta(minutes=30)).isoformat()
    resp = client.get("/api/slots/", {"activity": act.id, "after": ts})
    assert resp.status_code == 200
    assert len(resp.data) == 1
    assert resp.data[0]["id"] == later_slot.id
