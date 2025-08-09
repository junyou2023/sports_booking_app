import django
django.setup()
import pytest
from rest_framework.test import APIClient
from sports.models import Sport, Category, Variant

pytestmark = [pytest.mark.django_db]


def setup_activity(user):
    sport = Sport.objects.create(name="Climb")
    disc = Category.objects.create(name="Rock")
    var = Variant.objects.create(discipline=disc, name="Bouldering")
    from accounts.models import Organization, OrganizationMember
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    OrganizationMember.objects.create(
        organization=org, user=user, role="owner"
    )
    client = APIClient()
    client.force_authenticate(user)
    resp = client.post(
        "/api/activities/",
        {
            "sport": sport.id,
            "discipline": disc.id,
            "variant": var.id,
            "title": "Climb 101",
            "organization": org.id,
        },
    )
    return client, resp.data["id"]


def test_create_and_list_reviews(django_user_model):
    user = django_user_model.objects.create_user("u@example.com", "u@example.com", "pass")
    client, act_id = setup_activity(user)
    res = client.post(f"/api/activities/{act_id}/reviews/", {"rating": 5, "comment": "Nice"})
    assert res.status_code == 201
    res = client.get(f"/api/activities/{act_id}/reviews/", {"limit": 2})
    assert res.status_code == 200
    assert len(res.data) == 1
    assert res.data[0]["rating"] == 5
