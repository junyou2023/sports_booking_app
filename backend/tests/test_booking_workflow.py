import json
import django
import pytest
from django.utils import timezone
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from sports.models import Sport, Category, Facility, Activity, Slot, Booking
from accounts.models import Organization, OrganizationMember
from payments import views as pay_views


django.setup()
pytestmark = pytest.mark.django_db


def test_full_booking_flow(monkeypatch):
    """Simulate registration, slot creation and successful payment."""
    client = APIClient()

    # ---- Register vendor ----
    vendor_email = "vendor@example.com"
    password = "StrongPass123"
    reg = client.post(
        "/api/auth/registration/",
        {"email": vendor_email, "password1": password, "password2": password},
        format="json",
    )
    assert reg.status_code == 201
    vendor = User.objects.get(email=vendor_email)

    # ---- Login vendor ----
    token = client.post("/api/token/", {"email": vendor_email, "password": password})
    assert token.status_code == 200
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token.data['access']}")

    # ---- Setup organization and taxonomy ----
    org = Organization.objects.create(name="Org", slug="org-test")
    OrganizationMember.objects.create(organization=org, user=vendor, role="owner")
    sport = Sport.objects.create(name="Run")
    cat = Category.objects.create(name="Track")

    # ---- Create facility via API ----
    fac_resp = client.post(
        "/api/facilities/",
        {"name": "Stadium", "lat": 1, "lng": 2, "radius": 1000, "categories": [cat.id]},
        format="json",
    )
    assert fac_resp.status_code == 201
    facility_id = fac_resp.data["id"]
    assert Facility.objects.filter(id=facility_id).exists()

    # ---- Create activity via API ----
    act_resp = client.post(
        "/api/activities/",
        {
            "sport": sport.id,
            "discipline": cat.id,
            "title": "Morning Run",
            "difficulty": 1,
            "duration": 60,
            "base_price": "15.00",
            "organization": org.id,
        },
        format="json",
    )
    assert act_resp.status_code == 201
    activity_id = act_resp.data["id"]
    assert Activity.objects.filter(id=activity_id).exists()

    # ---- Create slot via API ----
    begins = timezone.now() + timezone.timedelta(hours=1)
    ends = begins + timezone.timedelta(hours=1)
    slot_resp = client.post(
        "/api/merchant/slots/",
        {
            "activity": activity_id,
            "facility": facility_id,
            "begins_at": begins.isoformat(),
            "ends_at": ends.isoformat(),
            "capacity": 5,
            "price": "15.00",
            "title": "Run Slot",
            "location": "Track",
        },
        format="json",
    )
    assert slot_resp.status_code == 201
    slot_id = slot_resp.data["id"]
    assert Slot.objects.filter(id=slot_id).exists()

    # ---- Register and login customer ----
    client.credentials()
    cust_email = "customer@example.com"
    reg2 = client.post(
        "/api/auth/registration/",
        {"email": cust_email, "password1": password, "password2": password},
        format="json",
    )
    assert reg2.status_code == 201
    customer = User.objects.get(email=cust_email)
    token2 = client.post("/api/token/", {"email": cust_email, "password": password})
    assert token2.status_code == 200
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token2.data['access']}")

    # ---- Checkout booking ----
    class FakeIntent:
        id = "pi_test"
        client_secret = "secret"

    monkeypatch.setattr(
        pay_views.stripe.PaymentIntent, "create", staticmethod(lambda **_: FakeIntent())
    )

    checkout = client.post(
        "/api/payments/checkout/", {"slot": slot_id}, format="json"
    )
    assert checkout.status_code == 200
    booking_id = checkout.data["booking_id"]
    booking = Booking.objects.get(id=booking_id)
    assert booking.status == "pending"
    assert not booking.paid

    # ---- Simulate Stripe webhook ----
    event = {
        "type": "payment_intent.succeeded",
        "data": {"object": {"metadata": {"slot_id": slot_id, "user_id": customer.id}}},
    }
    webhook = client.post(
        "/api/payments/webhook/",
        data=json.dumps(event),
        content_type="application/json",
    )
    assert webhook.status_code == 200
    booking.refresh_from_db()
    assert booking.paid
    assert booking.status == "confirmed"
