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
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        organization=org,
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
    items = resp.data.get("results", resp.data)
    if isinstance(items, dict) and "features" in items:
        items = items["features"]
    assert len(items) == 1
    first = items[0]
    if isinstance(first, dict) and "id" in first:
        first_id = first["id"]
    else:
        first_id = first.get("id")
    assert first_id == later_slot.id
