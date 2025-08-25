import json
import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from payments import views as pay_views
from sports.models import Booking
from backend.tests.utils.factories import user_factory, slot_factory

pytestmark = pytest.mark.django_db

class FakeIntent:
    id = "pi_test"
    client_secret = "cs_test"


def test_checkout_then_webhook_succeeded_confirms_booking(monkeypatch):
    user = user_factory()
    slot = slot_factory(capacity=5, begins_at=timezone.now() + timezone.timedelta(hours=2))

    monkeypatch.setattr(pay_views.stripe, "api_key", "sk_test")
    monkeypatch.setattr(pay_views.stripe.PaymentIntent, "create", lambda **kw: FakeIntent())
    client = APIClient()
    client.force_authenticate(user=user)
    resp = client.post("/api/payments/checkout/", {"slot": slot.id, "pax": 2}, format="json")
    assert resp.status_code == 200
    data = resp.json()
    booking_id = data["booking_id"]

    event = {
        "type": "payment_intent.succeeded",
        "data": {"object": {"id": FakeIntent.id, "metadata": {"slot_id": str(slot.id), "user_id": str(user.id)}}},
    }
    body = json.dumps(event).encode()
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_test")
    monkeypatch.setattr(pay_views.stripe.Webhook, "construct_event", lambda payload, sig, secret: event)
    w = client.post(
        "/api/payments/webhook/",
        data=body,
        content_type="application/json",
        HTTP_STRIPE_SIGNATURE="sig",
    )
    assert w.status_code in (200, 204)
    w2 = client.post(
        "/api/payments/webhook/",
        data=body,
        content_type="application/json",
        HTTP_STRIPE_SIGNATURE="sig",
    )
    assert w2.status_code in (200, 204)
    booking = Booking.objects.get(id=booking_id)
    assert booking.paid and booking.status == "confirmed"


@pytest.mark.xfail(reason="release-on-failure not implemented")
def test_webhook_failed_or_canceled_releases_seat_if_implemented(monkeypatch):
    user = user_factory()
    slot = slot_factory(capacity=1, begins_at=timezone.now() + timezone.timedelta(hours=2))
    monkeypatch.setattr(pay_views.stripe, "api_key", "sk_test")
    monkeypatch.setattr(pay_views.stripe.PaymentIntent, "create", lambda **kw: FakeIntent())
    client = APIClient(); client.force_authenticate(user=user)
    resp = client.post("/api/payments/checkout/", {"slot": slot.id, "pax": 1}, format="json")
    data = resp.json()
    event = {
        "type": "payment_intent.payment_failed",
        "data": {"object": {"id": FakeIntent.id, "metadata": {"slot_id": str(slot.id), "user_id": str(user.id)}}},
    }
    body = json.dumps(event).encode()
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_test")
    monkeypatch.setattr(pay_views.stripe.Webhook, "construct_event", lambda payload, sig, secret: event)
    client.post(
        "/api/payments/webhook/",
        data=body,
        content_type="application/json",
        HTTP_STRIPE_SIGNATURE="sig",
    )
    slot.refresh_from_db()
    assert slot.seats_left == slot.capacity
