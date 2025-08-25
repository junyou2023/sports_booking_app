import django
import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User

from sports.models import Sport, Category, Activity
from accounts.models import Organization, OrganizationMember


django.setup()
pytestmark = pytest.mark.django_db


def test_non_vendor_cannot_create_activity():
    user = User.objects.create_user(
        "normal", email="normal@example.com", password="pass12345"
    )
    # Remove vendor profile to simulate regular user
    user.vendorprofile.delete()
    user = User.objects.get(pk=user.pk)
    client = APIClient()
    client.force_authenticate(user)

    sport = Sport.objects.create(name="Run")
    cat = Category.objects.create(name="Track")
    org = Organization.objects.create(name="Org", slug="org-sec")
    resp = client.post(
        "/api/activities/",
        {"sport": sport.id, "discipline": cat.id, "title": "Act", "organization": org.id},
        format="json",
    )
    assert resp.status_code == 403


def test_search_sql_injection_handled(client):
    sport = Sport.objects.create(name="Bike")
    cat = Category.objects.create(name="Road")
    org = Organization.objects.create(name="Org", slug="org-sec2")
    Activity.objects.create(
        sport=sport,
        discipline=cat,
        organization=org,
        title="Ride",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
    )
    malicious = "'; DROP TABLE sports_activity; --"
    res = client.get("/api/activities/", {"q": malicious})
    assert res.status_code == 200
    assert Activity.objects.count() == 1
