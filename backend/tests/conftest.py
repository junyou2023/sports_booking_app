import pytest
import pytest
import django
import os
import pysqlite3
import sys
sys.modules["sqlite3"] = pysqlite3

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "PlayNexus.settings")
os.environ.setdefault("DB_HOST", "")
os.environ.setdefault("SPATIALITE_LIBRARY_PATH", "/usr/lib/x86_64-linux-gnu/mod_spatialite.so")
django.setup()
from django.utils import timezone
from rest_framework.test import APIClient


@pytest.fixture
def sport(db):
    from sports.models import Sport
    return Sport.objects.create(name="Tennis")


@pytest.fixture
def slot(db, sport, provider_user):
    from sports.models import Slot, Activity, Category
    cat = Category.objects.create(name="C")
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        organization=provider_user.org,
        title="Act",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
    )
    return Slot.objects.create(
        sport=sport,
        activity=act,
        title="Morning session",
        location="Court 1",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=4,
        price=0,
    )


@pytest.fixture
def client():
    """DRF APIClient fixture used in tests."""
    return APIClient()


@pytest.fixture
def provider_user(db):
    from django.contrib.auth.models import User
    user = User.objects.create_user("prov", email="prov@example.com", password="pass")
    from accounts.models import Organization, OrganizationMember
    from uuid import uuid4

    org = Organization.objects.create(name="Org", slug=f"org-{uuid4().hex[:8]}")
    OrganizationMember.objects.create(
        organization=org, user=user, role="owner"
    )
    user.org = org
    return user


@pytest.fixture
def auth_client(client, provider_user):
    client.force_authenticate(provider_user)
    return client
