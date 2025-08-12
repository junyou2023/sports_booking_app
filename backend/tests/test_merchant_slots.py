import pytest
from django.utils import timezone
from django.contrib.auth.models import User
from sports.models import Slot, Activity, Category, Sport


@pytest.fixture
def activity(provider_user, sport):
    cat = Category.objects.create(name="Cat")
    return Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="Act",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
        organization=provider_user.org,
    )


def test_create_update_overlap_400(auth_client, activity):
    begins = timezone.now() + timezone.timedelta(hours=1)
    ends = begins + timezone.timedelta(hours=1)
    resp = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "begins_at": begins.isoformat(),
            "ends_at": ends.isoformat(),
            "capacity": 5,
            "price": "0",
            "title": "S1",
            "location": "Loc",
        },
        format="json",
    )
    assert resp.status_code == 201
    slot_id = resp.data["id"]

    overlap_begins = begins + timezone.timedelta(minutes=30)
    overlap_ends = overlap_begins + timezone.timedelta(hours=1)
    resp2 = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "begins_at": overlap_begins.isoformat(),
            "ends_at": overlap_ends.isoformat(),
            "capacity": 5,
            "price": "0",
            "title": "S2",
            "location": "Loc",
        },
        format="json",
    )
    assert resp2.status_code == 400

    begins2 = ends
    ends2 = begins2 + timezone.timedelta(hours=1)
    resp3 = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "begins_at": begins2.isoformat(),
            "ends_at": ends2.isoformat(),
            "capacity": 5,
            "price": "0",
            "title": "S3",
            "location": "Loc",
        },
        format="json",
    )
    assert resp3.status_code == 201
    slot2_id = resp3.data["id"]

    resp4 = auth_client.patch(
        f"/api/merchant/slots/{slot2_id}/",
        {
            "begins_at": overlap_begins.isoformat(),
            "ends_at": overlap_ends.isoformat(),
        },
        format="json",
    )
    assert resp4.status_code == 400


def test_create_past_or_cross_day_400(auth_client, activity):
    past_begins = timezone.now() - timezone.timedelta(hours=1)
    past_ends = past_begins + timezone.timedelta(hours=1)
    resp = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "begins_at": past_begins.isoformat(),
            "ends_at": past_ends.isoformat(),
            "capacity": 5,
            "price": "0",
            "title": "Past",
            "location": "Loc",
        },
        format="json",
    )
    assert resp.status_code == 400

    begins = timezone.now() + timezone.timedelta(hours=1)
    ends = begins + timezone.timedelta(hours=25)
    resp2 = auth_client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "begins_at": begins.isoformat(),
            "ends_at": ends.isoformat(),
            "capacity": 5,
            "price": "0",
            "title": "Cross",
            "location": "Loc",
        },
        format="json",
    )
    assert resp2.status_code == 400


def test_bulk_delete_soft(auth_client, activity):
    begins = timezone.now() + timezone.timedelta(hours=1)
    ends = begins + timezone.timedelta(hours=1)
    ids = []
    for i in range(2):
        resp = auth_client.post(
            "/api/merchant/slots/",
            {
                "activity": activity.id,
                "begins_at": (begins + timezone.timedelta(hours=i)).isoformat(),
                "ends_at": (ends + timezone.timedelta(hours=i)).isoformat(),
                "capacity": 5,
                "price": "0",
                "title": f"S{i}",
                "location": "Loc",
            },
            format="json",
        )
        ids.append(resp.data["id"])

    resp = auth_client.delete(
        "/api/merchant/slots/bulk-delete/",
        {"ids": ids},
        format="json",
    )
    assert resp.status_code == 200
    assert resp.data["deleted"] == 2
    assert Slot.objects.filter(id__in=ids, is_active=False).count() == 2

    resp2 = auth_client.get("/api/merchant/slots/")
    assert resp2.status_code == 200
    assert resp2.data["count"] == 0
    assert resp2.data["results"] == []


def test_booking_flow_unchanged(db):
    user = User.objects.create_user("u1")
    sport = Sport.objects.create(name="S")
    cat = Category.objects.create(name="C")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    activity = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="A",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
        organization=org,
    )
    slot = Slot.objects.create(
        sport=sport,
        activity=activity,
        title="T",
        location="L",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=5,
        price=0,
        rating=0,
    )
    client = pytest.importorskip("rest_framework.test").APIClient()
    client.force_authenticate(user)
    resp = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    assert resp.status_code == 201


def test_booking_reject_soft_deleted_slot(db):
    user = User.objects.create_user("u2")
    sport = Sport.objects.create(name="S2")
    cat = Category.objects.create(name="C2")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O2", slug=f"o-{uuid4().hex[:8]}")
    activity = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="A2",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
        organization=org,
    )
    slot = Slot.objects.create(
        sport=sport,
        activity=activity,
        title="T2",
        location="L2",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=5,
        price=0,
        rating=0,
        is_active=False,
    )
    client = pytest.importorskip("rest_framework.test").APIClient()
    client.force_authenticate(user)
    resp = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    assert resp.status_code == 400
