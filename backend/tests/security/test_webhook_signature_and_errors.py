import json
import pytest
from rest_framework.test import APIClient
from payments import views as pay_views
import stripe

pytestmark = pytest.mark.django_db


def test_webhook_without_signature_rejected(monkeypatch):
    client = APIClient()
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec")
    def boom(payload, sig, secret):
        raise stripe.error.SignatureVerificationError("no sig", sig)
    monkeypatch.setattr(pay_views.stripe.Webhook, "construct_event", boom)
    resp = client.post(
        "/api/payments/webhook/",
        data=json.dumps({"type": "ping"}),
        content_type="application/json",
    )
    assert resp.status_code in (400, 401)
