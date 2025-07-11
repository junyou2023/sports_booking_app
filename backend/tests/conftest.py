import pytest
from django.utils import timezone
from rest_framework.test import APIClient

@pytest.fixture
def sport(db):
    from backend.sports.models import Sport
    return Sport.objects.create(name="Tennis")

@pytest.fixture
def slot(db, sport):
    from backend.sports.models import Slot
    return Slot.objects.create(
        sport=sport,
        title="Morning session",
        location="Court 1",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=4,
    )


@pytest.fixture
def client():
    """DRF APIClient fixture used in tests."""
    return APIClient()