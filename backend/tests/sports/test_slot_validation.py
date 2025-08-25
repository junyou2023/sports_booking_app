import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from backend.tests.utils.factories import vendor_factory, activity_factory

pytestmark = pytest.mark.django_db


@pytest.mark.xfail(reason="ends_at > begins_at not enforced")
def test_slot_end_must_after_begin():
    vendor = vendor_factory()
    activity = activity_factory(organization=vendor.org)
    client = APIClient(); client.force_authenticate(user=vendor.user)
    begins = timezone.now() + timezone.timedelta(hours=4)
    ends = begins
    resp = client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "title": "S",
            "location": "L",
            "begins_at": begins.isoformat(),
            "ends_at": ends.isoformat(),
            "capacity": 5,
            "price": "9.99",
        },
        format="json",
    )
    assert resp.status_code in (400, 422)


@pytest.mark.xfail(reason="min duration / same-day rules not enforced")
def test_slot_min_duration_and_same_day():
    vendor = vendor_factory()
    activity = activity_factory(organization=vendor.org)
    client = APIClient(); client.force_authenticate(user=vendor.user)
    begins = timezone.now().replace(minute=0, second=0, microsecond=0) + timezone.timedelta(hours=23)
    ends = begins + timezone.timedelta(hours=2)
    resp = client.post(
        "/api/merchant/slots/",
        {
            "activity": activity.id,
            "title": "S",
            "location": "L",
            "begins_at": begins.isoformat(),
            "ends_at": ends.isoformat(),
            "capacity": 5,
            "price": "9.99",
        },
        format="json",
    )
    assert resp.status_code in (400, 422)
