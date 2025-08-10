from django.contrib.auth.models import User
from django.core.management import call_command
from django.utils import timezone
import pytest

from sports.models import Booking, Activity, Slot, Category, Sport

pytestmark = pytest.mark.django_db


@pytest.fixture
def activity(provider_user):
    sport = Sport.objects.create(name="S")
    cat = Category.objects.create(name="CatN")
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


@pytest.fixture
def slot(activity):
    begins = timezone.now() + timezone.timedelta(hours=1)
    ends = begins + timezone.timedelta(hours=1)
    return Slot.objects.create(
        activity=activity,
        sport=activity.sport,
        title="S",
        location="L",
        begins_at=begins,
        ends_at=ends,
        capacity=100,
        price=0,
    )


def test_paged_list_cursor_filters(auth_client, activity, slot):
    for i in range(55):
        u = User.objects.create_user(f"u{i}")
        Booking.objects.create(
            slot=slot,
            activity=activity,
            user=u,
            pax=1,
            status="pending",
            paid=False,
            booked_at=timezone.now() - timezone.timedelta(minutes=i),
        )
    u = User.objects.create_user("conf")
    Booking.objects.create(
        slot=slot,
        activity=activity,
        user=u,
        pax=1,
        status="confirmed",
        paid=True,
    )
    resp_old = auth_client.get("/api/merchant/bookings/")
    assert resp_old.status_code == 200
    assert isinstance(resp_old.data, list)
    assert len(resp_old.data) == 56

    resp = auth_client.get("/api/merchant/bookings/paged/?status=pending")
    assert resp.status_code == 200
    assert "results" in resp.data and len(resp.data["results"]) == 50
    next_url = resp.data["next"]
    assert next_url
    resp2 = auth_client.get(next_url)
    assert len(resp2.data["results"]) == 5
    assert all(b["status"] == "pending" for b in resp.data["results"])


def test_cancel_pending_and_confirmed(auth_client, activity, slot):
    u1 = User.objects.create_user("p1")
    u2 = User.objects.create_user("p2")
    pending = Booking.objects.create(slot=slot, activity=activity, user=u1, pax=1, status="pending", paid=False)
    confirmed = Booking.objects.create(slot=slot, activity=activity, user=u2, pax=1, status="confirmed", paid=False)
    slot.current_participants = 2
    slot.save(update_fields=["current_participants"])
    resp1 = auth_client.post(f"/api/merchant/bookings/{pending.id}/cancel/")
    assert resp1.status_code == 200
    pending.refresh_from_db()
    assert pending.status == "cancelled"
    resp2 = auth_client.post(f"/api/merchant/bookings/{confirmed.id}/cancel/")
    assert resp2.status_code == 200
    confirmed.refresh_from_db()
    assert confirmed.status == "cancelled"
    u3 = User.objects.create_user("p3")
    completed = Booking.objects.create(slot=slot, activity=activity, user=u3, pax=1, status="completed", paid=True)
    resp3 = auth_client.post(f"/api/merchant/bookings/{completed.id}/cancel/")
    assert resp3.status_code == 400


def test_refund_success_and_failure(auth_client, activity, slot, monkeypatch):
    u1 = User.objects.create_user("r1")
    b1 = Booking.objects.create(slot=slot, activity=activity, user=u1, pax=1, status="confirmed", paid=True, payment_intent_id="pi_1")
    slot.current_participants = 2
    slot.save(update_fields=["current_participants"])
    def ok(_):
        return None
    monkeypatch.setattr("sports.merchant_views.refund", ok)
    resp = auth_client.post(f"/api/merchant/bookings/{b1.id}/cancel/")
    assert resp.status_code == 200
    b1.refresh_from_db()
    assert b1.status == "refunded"

    u2 = User.objects.create_user("r2")
    b2 = Booking.objects.create(slot=slot, activity=activity, user=u2, pax=1, status="confirmed", paid=True, payment_intent_id="pi_2")
    def boom(_):
        raise Exception("fail")
    monkeypatch.setattr("sports.merchant_views.refund", boom)
    resp2 = auth_client.post(f"/api/merchant/bookings/{b2.id}/cancel/")
    assert resp2.status_code == 502
    b2.refresh_from_db()
    assert b2.status == "confirmed"


def test_timeout_job_or_command(activity, slot):
    u = User.objects.create_user("t1")
    b = Booking.objects.create(slot=slot, activity=activity, user=u, pax=1, status="pending", paid=False, booked_at=timezone.now() - timezone.timedelta(minutes=31))
    slot.current_participants = 1
    slot.save(update_fields=["current_participants"])
    call_command("bookings_cancel_timeouts")
    b.refresh_from_db()
    assert b.status == "cancelled"


def test_concurrency_unchanged(db):
    sport = Sport.objects.create(name="S")
    cat = Category.objects.create(name="C")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="Org", slug=f"org-{uuid4().hex[:8]}")
    activity = Activity.objects.create(sport=sport, discipline=cat, title="A", description="", difficulty=1, duration=60, base_price=0, organization=org)
    begins = timezone.now() + timezone.timedelta(hours=1)
    ends = begins + timezone.timedelta(hours=1)
    slot = Slot.objects.create(activity=activity, sport=sport, title="T", location="L", begins_at=begins, ends_at=ends, capacity=1, price=0)
    u1 = User.objects.create_user("u1")
    u2 = User.objects.create_user("u2")
    client1 = pytest.importorskip("rest_framework.test").APIClient()
    client2 = pytest.importorskip("rest_framework.test").APIClient()
    client1.force_authenticate(u1)
    client2.force_authenticate(u2)
    r1 = client1.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    r2 = client2.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    assert [r1.status_code, r2.status_code].count(201) == 1
