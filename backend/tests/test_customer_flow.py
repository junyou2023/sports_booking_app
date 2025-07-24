import django
import pytest
from rest_framework.test import APIClient
from django.contrib.gis.geos import Point
from django.utils import timezone
from django.contrib.auth.models import User
from sports.models import (
    Sport,
    Category,
    Activity,
    Facility,
    Slot,
    Booking,
)

django.setup()
pytestmark = pytest.mark.django_db


def setup_activity():
    sport = Sport.objects.create(name="Golf")
    cat = Category.objects.create(name="Outdoor")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="Golf 101",
        status=Activity.STATUS_PUBLISHED,
    )
    fac = Facility.objects.create(name="Course", location=Point(0, 0))
    Slot.objects.create(
        activity=act,
        facility=fac,
        sport=sport,
        title="Morning",
        location="Loc",
        begins_at=timezone.now() + timezone.timedelta(days=1),
        ends_at=timezone.now() + timezone.timedelta(days=1, hours=1),
        capacity=5,
        price=10,
        rating=4.5,
    )
    return sport, act


def test_activity_search_by_location_date():
    sport, act = setup_activity()
    client = APIClient()
    target_date = (
        timezone.now() + timezone.timedelta(days=1)
    ).date().isoformat()
    resp = client.get(
        "/api/activities/",
        {
            "sport": sport.id,
            "lat": 0,
            "lng": 0,
            "radius": 1000,
            "date": target_date,
        },
    )
    assert resp.status_code == 200
    assert len(resp.data) == 1
    assert resp.data[0]["id"] == act.id
    assert float(resp.data[0]["starting_price"]) == 10.0


def test_slot_list_filters_available_date():
    sport, act = setup_activity()
    # past sold-out slot
    past = Slot.objects.create(
        activity=act,
        sport=sport,
        title="Past",
        location="Loc",
        begins_at=timezone.now() - timezone.timedelta(days=1),
        ends_at=timezone.now() - timezone.timedelta(days=1, hours=-1),
        capacity=1,
        price=5,
    )
    past.current_participants = 1
    past.save()

    client = APIClient()
    target_date = (
        timezone.now() + timezone.timedelta(days=1)
    ).date().isoformat()
    resp = client.get("/api/slots/", {"activity": act.id, "date": target_date})
    assert resp.status_code == 200
    assert len(resp.data) == 1
    assert resp.data[0]["sold_out"] is False


def test_booking_list_tabs():
    sport, act = setup_activity()
    future_slot = act.slots.first()
    past_slot = Slot.objects.create(
        activity=act,
        sport=sport,
        title="Past",
        location="Loc",
        begins_at=timezone.now() - timezone.timedelta(days=1),
        ends_at=timezone.now() - timezone.timedelta(days=1, hours=-1),
        capacity=1,
        price=5,
    )
    user = User.objects.create_user("cust")
    b1 = Booking.objects.create(
        slot=future_slot,
        activity=act,
        user=user,
        status="confirmed",
    )
    b2 = Booking.objects.create(
        slot=past_slot,
        activity=act,
        user=user,
        status="confirmed",
    )
    other_slot = Slot.objects.create(
        activity=act,
        sport=sport,
        title="Other",
        location="Loc",
        begins_at=timezone.now() + timezone.timedelta(days=2),
        ends_at=timezone.now() + timezone.timedelta(days=2, hours=1),
        capacity=1,
        price=5,
    )
    b3 = Booking.objects.create(
        slot=other_slot,
        activity=act,
        user=user,
        status="cancelled",
    )
    c = APIClient()
    c.force_authenticate(user)
    resp = c.get("/api/bookings/", {"tab": "upcoming"})
    assert {row["id"] for row in resp.data} == {b1.id}
    resp = c.get("/api/bookings/", {"tab": "completed"})
    assert {row["id"] for row in resp.data} == {b2.id}
    resp = c.get("/api/bookings/", {"tab": "cancelled"})
    assert {row["id"] for row in resp.data} == {b3.id}
