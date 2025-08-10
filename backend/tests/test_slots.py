import django
import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from django.db import connection

import django
import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from django.db import connection

from sports.models import Category, Activity, Slot

django.setup()
pytestmark = pytest.mark.django_db


def create_activity(provider_user, sport):
    cat = Category.objects.create(name="Cat")
    return Activity.objects.create(
        sport=sport,
        discipline=cat,
        organization=provider_user.org,
        title="Act",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
    )


def test_slot_create_past_400(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    past = timezone.now() - timezone.timedelta(hours=1)
    resp = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": act.id,
            "begins_at": past.isoformat(),
            "ends_at": (past + timezone.timedelta(hours=1)).isoformat(),
            "capacity": 5,
            "price": 0,
            "title": "S",
            "location": "L",
        },
        format="json",
    )
    assert resp.status_code == 400


def test_slot_create_cross_day_400(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    start = timezone.now().replace(hour=23, minute=0, second=0, microsecond=0)
    resp = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": act.id,
            "begins_at": start.isoformat(),
            "ends_at": (start + timezone.timedelta(hours=2)).isoformat(),
            "capacity": 5,
            "price": 0,
            "title": "S",
            "location": "L",
        },
        format="json",
    )
    assert resp.status_code == 400


def test_slot_update_overlap_400(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    now = timezone.now()
    s1 = Slot.objects.create(
        activity=act,
        sport=sport,
        title="A",
        location="L",
        begins_at=now + timezone.timedelta(hours=1),
        ends_at=now + timezone.timedelta(hours=2),
        capacity=5,
        price=0,
    )
    s2 = Slot.objects.create(
        activity=act,
        sport=sport,
        title="B",
        location="L",
        begins_at=now + timezone.timedelta(hours=3),
        ends_at=now + timezone.timedelta(hours=4),
        capacity=5,
        price=0,
    )
    resp = auth_client.put(
        f"/api/merchant/slots/{s2.id}/",
        {
            "begins_at": (now + timezone.timedelta(hours=1, minutes=30)).isoformat(),
            "ends_at": (now + timezone.timedelta(hours=2, minutes=30)).isoformat(),
            "capacity": 5,
            "price": 0,
            "title": "B",
            "location": "L",
        },
        format="json",
    )
    assert resp.status_code == 400


def test_bulk_delete_soft(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    now = timezone.now()
    s1 = Slot.objects.create(
        activity=act,
        sport=sport,
        title="S1",
        location="L",
        begins_at=now + timezone.timedelta(hours=1),
        ends_at=now + timezone.timedelta(hours=2),
        capacity=5,
        price=0,
    )
    s2 = Slot.objects.create(
        activity=act,
        sport=sport,
        title="S2",
        location="L",
        begins_at=now + timezone.timedelta(hours=3),
        ends_at=now + timezone.timedelta(hours=4),
        capacity=5,
        price=0,
    )
    resp = auth_client.delete(
        "/api/merchant/slots/bulk-delete/",
        {"ids": [s1.id, s2.id]},
        format="json",
    )
    assert resp.status_code == 200
    assert resp.data["deleted"] == 2
    resp = auth_client.get("/api/slots/", {"activity": act.id})
    assert resp.data == []
    assert Slot.objects.filter(id=s1.id).exists()
    assert not Slot.objects.get(id=s1.id).is_active


def test_bulk_create_conflict_batch_reject(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    now = timezone.now().replace(minute=0, second=0, microsecond=0) + timezone.timedelta(hours=2)
    Slot.objects.create(
        activity=act,
        sport=sport,
        title="E",
        location="L",
        begins_at=now + timezone.timedelta(hours=1),
        ends_at=now + timezone.timedelta(hours=2),
        capacity=5,
        price=0,
    )
    resp = auth_client.post(
        "/api/merchant/slots/bulk-create/",
        {
            "activity": act.id,
            "start_time": (now).isoformat(),
            "end_time": (now + timezone.timedelta(hours=3)).isoformat(),
            "interval": 60,
            "capacity": 5,
            "price": 0,
        },
        format="json",
    )
    assert resp.status_code == 400
    assert resp.data["detail"] == "conflict"
    assert len(resp.data["examples"]) >= 1
    assert Slot.objects.filter(activity=act).count() == 1


def test_slot_indexes_exist(db):
    with connection.cursor() as cursor:
        constraints = connection.introspection.get_constraints(cursor, Slot._meta.db_table)
    indexes = [tuple(v["columns"]) for v in constraints.values() if v.get("index")]
    assert ("activity_id", "begins_at") in indexes
    assert ("activity_id", "ends_at") in indexes
