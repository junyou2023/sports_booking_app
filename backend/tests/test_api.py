"""
Very light smoke-tests proving that all endpoints work.
Run:  pytest backend
"""
import pytest
import django
from rest_framework.test import APIClient
from sports.models import Sport, Slot, Booking, Category, Activity, UserActivityHistory
from django.contrib.auth.models import User
from django.utils import timezone
import json
from django.db import models
from accounts.models import Organization
from uuid import uuid4

django.setup()


pytestmark = pytest.mark.django_db


def test_sports_list():
    Sport.objects.create(name="Tennis1")
    client = APIClient()
    response = client.get("/api/sports/")
    assert response.status_code == 200


def test_slots_filter():
    sport = Sport.objects.create(name="Biking1")
    cat = Category.objects.create(name="C1")
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
    Slot.objects.create(
        sport=sport,
        activity=act,
        title="Morning Ride",
        location="Park",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=10,
        price=0,
        rating=4.5,
    )
    client = APIClient()
    response = client.get("/api/slots/", {"sport": sport.id})
    assert response.status_code == 200


def test_slot_requires_activity():
    sport = Sport.objects.create(name="Hoops")
    with pytest.raises(Exception):
        Slot.objects.create(
            sport=sport,
            title="M",
            location="L",
            begins_at=timezone.now(),
            ends_at=timezone.now() + timezone.timedelta(hours=1),
            capacity=1,
            price=0,
            rating=0,
        )


def test_booking_creation():
    user = User.objects.create_user("demo_api", password="demo123")
    sport = Sport.objects.create(name="Kayak1")
    cat = Category.objects.create(name="C2")
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
    slot = Slot.objects.create(
        sport=sport,
        activity=act,
        title="Evening Ride",
        location="Lake",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
        price=10,
        rating=4.0,
    )
    client = APIClient()
    client.force_authenticate(user)
    response = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 2})
    assert response.status_code == 201
    assert Booking.objects.filter(user=user, slot=slot).exists()


def test_concurrent_booking_capacity(db):
    user1 = User.objects.create_user("u1")
    user2 = User.objects.create_user("u2")
    sport = Sport.objects.create(name="Swim")
    cat = Category.objects.create(name="C3")
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
    slot = Slot.objects.create(
        sport=sport,
        activity=act,
        title="M",
        location="L",
        begins_at=timezone.now() + timezone.timedelta(minutes=1),
        ends_at=timezone.now() + timezone.timedelta(hours=1, minutes=1),
        capacity=1,
        price=0,
        rating=0,
    )

    c1 = APIClient(); c1.force_authenticate(user1)
    c2 = APIClient(); c2.force_authenticate(user2)
    r1 = c1.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    r2 = c2.post("/api/bookings/", {"slot_id": slot.id, "pax": 1})
    assert [r1.status_code, r2.status_code].count(201) == 1
    assert (
        Booking.objects.filter(slot=slot).aggregate(models.Sum("pax"))["pax__sum"]
        <= slot.capacity
    )


def test_slots_filter_by_activity():
    sport = Sport.objects.create(name="Yoga")
    disc = Category.objects.create(name="Flow")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    activity = Activity.objects.create(
        sport=sport,
        discipline=disc,
        title="Morning Flow",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
        organization=org,
    )
    start = timezone.now() + timezone.timedelta(minutes=1)
    slot = Slot.objects.create(
        sport=sport,
        activity=activity,
        title="Morning",
        location="Room",
        begins_at=start,
        ends_at=start + timezone.timedelta(hours=1),
        capacity=5,
        price=0,
        rating=0,
    )
    client = APIClient()
    resp = client.get("/api/slots/", {"activity": activity.id})
    assert resp.status_code == 200
    assert len(resp.data) == 1
    assert resp.data[0]["id"] == slot.id


def test_continue_planning_endpoint():
    user = User.objects.create_user("planu")
    sport = Sport.objects.create(name="Run")
    cat = Category.objects.create(name="Aerobic")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="Morning Run",
        description="",
        difficulty=1,
        duration=30,
        base_price=5,
        organization=org,
    )
    UserActivityHistory.objects.create(
        user=user, activity=act, action="view"
    )

    client = APIClient()
    client.force_authenticate(user)
    resp = client.get("/api/home/continue-planning/")
    assert resp.status_code == 200
    assert len(resp.data) == 1
    assert resp.data[0]["title"] == "Morning Run"


def test_webhook_updates_booking(monkeypatch, client=None):
    sport = Sport.objects.create(name="Foot")
    cat = Category.objects.create(name="Play")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="Match",
        description="",
        difficulty=1,
        duration=60,
        base_price=10,
        organization=org,
    )
    slot = Slot.objects.create(
        sport=sport,
        activity=act,
        title="M",
        location="L",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
        price=10,
        rating=0,
    )
    user = User.objects.create_user("web")
    booking = Booking.objects.create(slot=slot, activity=act, user=user)
    client = APIClient()
    event = {
        "type": "payment_intent.succeeded",
        "data": {"object": {"id": "pi_1", "metadata": {"slot_id": slot.id, "user_id": user.id}}},
    }
    from payments import views as pay_views
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec")
    def fake_construct(payload, sig, secret):
        return event
    monkeypatch.setattr(pay_views.stripe.Webhook, 'construct_event', staticmethod(fake_construct))
    res = client.post(
        "/api/payments/webhook/",
        data=json.dumps(event),
        content_type="application/json",
    )
    assert res.status_code == 200
    booking.refresh_from_db()
    assert booking.paid
    assert booking.status == "confirmed"
