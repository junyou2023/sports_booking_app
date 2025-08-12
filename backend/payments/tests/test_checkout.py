import os
import sys
import pysqlite3
import django

sys.modules["sqlite3"] = pysqlite3

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "PlayNexus.settings")
os.environ.setdefault("DB_HOST", "")
os.environ.setdefault(
    "SPATIALITE_LIBRARY_PATH", "/usr/lib/x86_64-linux-gnu/mod_spatialite.so"
)

django.setup()

import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot, Booking
import stripe
from payments import views as pay_views


pytestmark = pytest.mark.django_db


@pytest.fixture
def user():
    return User.objects.create_user("u1", email="u1@example.com", password="pass")


@pytest.fixture
def auth_client(user):
    client = APIClient()
    client.force_authenticate(user)
    return client


@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def slot():
    sport = Sport.objects.create(name="X")
    cat = Category.objects.create(name="C")
    from accounts.models import Organization
    from uuid import uuid4

    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="A",
        description="",
        difficulty=1,
        duration=60,
        base_price=10,
        organization=org,
    )
    return Slot.objects.create(
        sport=sport,
        activity=act,
        title="S",
        location="L",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=5,
        price=10,
    )


def test_checkout_requires_auth(client, slot):
    resp = client.post("/api/payments/checkout/", {"slot": slot.id})
    assert resp.status_code == 401


def test_checkout_invalid_slot(auth_client):
    resp = auth_client.post("/api/payments/checkout/", {"slot": 9999})
    assert resp.status_code == 400
    assert resp.data["detail"] == "invalid slot"


def test_checkout_missing_key_returns_500(auth_client, slot, monkeypatch):
    monkeypatch.setattr(pay_views.stripe, "api_key", "")
    resp = auth_client.post("/api/payments/checkout/", {"slot": slot.id})
    assert resp.status_code == 500


def test_checkout_creates_intent(auth_client, user, slot, monkeypatch):
    class FakeIntent:
        id = "pi_new"
        client_secret = "sec"
        status = "requires_payment_method"

    def fake_create(**kwargs):
        assert (
            kwargs["idempotency_key"]
            == f"user-{user.id}-slot-{slot.id}"
        )
        return FakeIntent()

    monkeypatch.setattr(pay_views.stripe.PaymentIntent, "create", staticmethod(fake_create))
    monkeypatch.setattr(pay_views.stripe, "api_key", "sk_test_123")
    resp = auth_client.post("/api/payments/checkout/", {"slot": slot.id})
    assert resp.status_code == 200
    assert resp.data["payment_intent_id"] == "pi_new"
    booking = Booking.objects.get(id=resp.data["booking_id"])
    assert booking.payment_intent_id == "pi_new"


def test_checkout_reuses_intent(auth_client, user, slot, monkeypatch):
    booking = Booking.objects.create(
        slot=slot, activity=slot.activity, user=user, payment_intent_id="pi_old"
    )

    class FakeIntent:
        id = "pi_old"
        client_secret = "sec"
        status = "requires_action"

    def fake_retrieve(intent_id):
        assert intent_id == "pi_old"
        return FakeIntent()

    monkeypatch.setattr(pay_views.stripe.PaymentIntent, "retrieve", staticmethod(fake_retrieve))
    monkeypatch.setattr(pay_views.stripe, "api_key", "sk_test_123")
    resp = auth_client.post("/api/payments/checkout/", {"slot": slot.id})
    assert resp.status_code == 200
    assert resp.data["payment_intent_id"] == "pi_old"
    booking.refresh_from_db()
    assert booking.payment_intent_id == "pi_old"


def test_checkout_creates_new_after_cancel(auth_client, user, slot, monkeypatch):
    booking = Booking.objects.create(
        slot=slot, activity=slot.activity, user=user, payment_intent_id="pi_old"
    )

    class OldIntent:
        id = "pi_old"
        client_secret = "old"
        status = "canceled"

    class NewIntent:
        id = "pi_new"
        client_secret = "new"
        status = "requires_payment_method"

    monkeypatch.setattr(
        pay_views.stripe.PaymentIntent, "retrieve", staticmethod(lambda _id: OldIntent())
    )
    monkeypatch.setattr(
        pay_views.stripe.PaymentIntent, "create", staticmethod(lambda **_: NewIntent())
    )
    monkeypatch.setattr(pay_views.stripe, "api_key", "sk_test_123")

    resp = auth_client.post("/api/payments/checkout/", {"slot": slot.id})
    assert resp.data["payment_intent_id"] == "pi_new"
    booking.refresh_from_db()
    assert booking.payment_intent_id == "pi_new"


def test_confirm_marks_paid(auth_client, user, slot, monkeypatch):
    booking = Booking.objects.create(
        slot=slot,
        activity=slot.activity,
        user=user,
        payment_intent_id="pi_1",
        status="pending",
        paid=False,
    )

    class Intent:
        id = "pi_1"
        status = "succeeded"

    monkeypatch.setattr(
        pay_views.stripe.PaymentIntent, "retrieve", staticmethod(lambda _id: Intent())
    )
    resp = auth_client.get("/api/payments/confirm/pi_1/")
    assert resp.status_code == 200
    booking.refresh_from_db()
    assert booking.paid is True
    assert booking.status == "confirmed"


def test_webhook_signature_success(user, slot, monkeypatch):
    booking = Booking.objects.create(
        slot=slot, activity=slot.activity, user=user, payment_intent_id="pi_w"
    )

    event = {
        "type": "payment_intent.succeeded",
        "data": {
            "object": {
                "id": "pi_w",
                "metadata": {"slot_id": slot.id, "user_id": user.id},
            }
        },
    }

    def fake_construct_event(payload, sig, secret):
        return event

    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec")
    monkeypatch.setattr(
        pay_views.stripe.Webhook, "construct_event", staticmethod(fake_construct_event)
    )
    client = APIClient()
    resp = client.post(
        "/api/payments/webhook/",
        data="{}",
        content_type="application/json",
        HTTP_STRIPE_SIGNATURE="sig",
    )
    assert resp.status_code == 200
    booking.refresh_from_db()
    assert booking.paid


def test_webhook_signature_failure(monkeypatch):
    def fake_construct_event(payload, sig, secret):
        raise stripe.error.SignatureVerificationError("bad", sig)

    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec")
    monkeypatch.setattr(
        pay_views.stripe.Webhook, "construct_event", staticmethod(fake_construct_event)
    )
    client = APIClient()
    resp = client.post(
        "/api/payments/webhook/",
        data="{}",
        content_type="application/json",
        HTTP_STRIPE_SIGNATURE="sig",
    )
    assert resp.status_code == 400

