import pytest
from django.utils import timezone
from django.contrib.auth.models import User
from backend.sports.models import Sport, Slot

@pytest.fixture
def user(db):
    return User.objects.create_user(username="merchant", password="pass")


@pytest.fixture
def sport(db):
    return Sport.objects.create(name="Tennis")

@pytest.fixture
def slot(db, sport, user):
    return Slot.objects.create(
        sport=sport,
        title="Morning session",
        location="Court 1",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=4,
        owner=user,
    )
