import django
import json
import pytest
from rest_framework.test import APIClient
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot, Booking

django.setup()
pytestmark = pytest.mark.django_db


def test_payment_webhook_updates_booking():
    sport = Sport.objects.create(name="Pay")
    cat = Category.objects.create(name="Cat")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="Match",
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
        capacity=5,
        price=10,
        rating=0,
    )
    user_id = 1
    booking = Booking.objects.create(slot=slot, activity=act, user_id=user_id)
    client = APIClient()
    event = {
        "type": "payment_intent.succeeded",
        "data": {
            "object": {
                "metadata": {"slot_id": slot.id, "user_id": user_id}
            }
        },
    }
    res = client.post(
        "/api/payments/webhook/",
        data=json.dumps(event),
        content_type="application/json",
    )
    assert res.status_code == 200
    booking.refresh_from_db()
    assert booking.paid
    assert booking.status == "confirmed"
