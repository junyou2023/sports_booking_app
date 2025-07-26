import stripe
import django
import pytest
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot, Booking

django.setup()
pytestmark = pytest.mark.django_db


def _setup_slot():
    sport = Sport.objects.create(name="Ball")
    cat = Category.objects.create(name="C")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="A",
        description="",
        difficulty=1,
        duration=60,
        base_price=10,
    )
    slot = Slot.objects.create(
        sport=sport,
        activity=act,
        title="S",
        location="L",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=1,
        price=10,
        rating=0,
    )
    return slot


def test_checkout_missing_api_key(auth_client, provider_user):
    slot = _setup_slot()
    stripe.api_key = ""
    res = auth_client.post("/api/payments/checkout/", {"slot": slot.id})
    assert res.status_code == 500
    assert "misconfigured" in res.data["detail"]


def test_checkout_success(monkeypatch, auth_client, provider_user):
    slot = _setup_slot()
    stripe.api_key = "sk_test"

    class DummyIntent:
        client_secret = "cs"
        id = "pi_1"

    def fake_create(**kwargs):
        return DummyIntent()

    monkeypatch.setattr(stripe.PaymentIntent, "create", fake_create)

    res = auth_client.post("/api/payments/checkout/", {"slot": slot.id})
    assert res.status_code == 200
    data = res.json()
    assert data["client_secret"] == "cs"
    assert Booking.objects.filter(id=data["booking_id"], user=provider_user).exists()

