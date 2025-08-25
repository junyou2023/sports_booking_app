import django
import json
import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot, Booking
from unittest.mock import patch

django.setup()
pytestmark = pytest.mark.django_db


def test_payment_webhook_updates_booking():
    sport = Sport.objects.create(name="Pay")
    cat = Category.objects.create(name="Cat")
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
        title="S",
        location="L",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=5,
        price=10,
        rating=0,
    )
    from django.contrib.auth.models import User
    user = User.objects.create_user("webhook")
    booking = Booking.objects.create(slot=slot, activity=act, user=user)
    client = APIClient()
    event = {
        "type": "payment_intent.succeeded",
        "data": {
            "object": {
                "id": "pi_test",
                "metadata": {"slot_id": slot.id, "user_id": user.id}
            }
        },
    }
    headers = {"HTTP_STRIPE_SIGNATURE": "t=1,v1=fake"}
    with patch("stripe.Webhook.construct_event", return_value=event):
        res = client.post(
            "/api/payments/webhook/",
            data=event,
            content_type="application/json",
            **headers,
        )
    assert res.status_code == 200
    booking.refresh_from_db()
    assert booking.paid
    assert booking.status == "confirmed"
