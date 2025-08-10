import django
import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from django.db import connection
from decimal import Decimal

from django.contrib.auth.models import User
from sports.models import Category, Activity, Slot, PriceRule, Booking

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


def test_pricing_rule_override(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    start = timezone.now() + timezone.timedelta(hours=1)
    slot = Slot.objects.create(
        activity=act,
        sport=sport,
        title="S",
        location="L",
        begins_at=start,
        ends_at=start + timezone.timedelta(hours=1),
        capacity=5,
        price=Decimal("20.00"),
    )
    rule = PriceRule.objects.create(
        activity=act,
        weekday=slot.begins_at.weekday(),
        time_start=slot.begins_at.time(),
        time_end=slot.ends_at.time(),
        price=Decimal("15.00"),
    )
    customer = User.objects.create_user("cust", password="pass")
    client = APIClient()
    client.force_authenticate(customer)
    resp = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 1}, format="json")
    assert resp.status_code == 201
    booking = Booking.objects.get(id=resp.data["id"])
    assert booking.price == rule.price


def test_pricing_rule_specific_and_latest(auth_client, provider_user, sport):
    act = create_activity(provider_user, sport)
    start = timezone.now().replace(minute=0, second=0, microsecond=0) + timezone.timedelta(hours=1)
    slot = Slot.objects.create(
        activity=act,
        sport=sport,
        title="S",
        location="L",
        begins_at=start + timezone.timedelta(minutes=30),
        ends_at=start + timezone.timedelta(minutes=90),
        capacity=5,
        price=Decimal("50.00"),
    )
    PriceRule.objects.create(
        activity=act,
        weekday=slot.begins_at.weekday(),
        time_start=start.time(),
        time_end=(start + timezone.timedelta(hours=4)).time(),
        price=Decimal("40.00"),
    )
    PriceRule.objects.create(
        activity=act,
        weekday=slot.begins_at.weekday(),
        time_start=(start + timezone.timedelta(minutes=15)).time(),
        time_end=(start + timezone.timedelta(minutes=105)).time(),
        price=Decimal("35.00"),
    )
    latest = PriceRule.objects.create(
        activity=act,
        weekday=slot.begins_at.weekday(),
        time_start=(start + timezone.timedelta(minutes=15)).time(),
        time_end=(start + timezone.timedelta(minutes=105)).time(),
        price=Decimal("25.00"),
    )
    customer = User.objects.create_user("cust2", password="pass")
    client = APIClient()
    client.force_authenticate(customer)
    resp = client.post("/api/bookings/", {"slot_id": slot.id, "pax": 1}, format="json")
    assert resp.status_code == 201
    booking = Booking.objects.get(id=resp.data["id"])
    assert booking.price == latest.price


def test_pricerule_index(db):
    with connection.cursor() as cursor:
        constraints = connection.introspection.get_constraints(cursor, PriceRule._meta.db_table)
    indexes = [tuple(v["columns"]) for v in constraints.values() if v.get("index")]
    assert ("activity_id", "weekday", "time_start", "time_end") in indexes
