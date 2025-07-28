import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from sports.models import Sport, Category, Activity, Slot, FeaturedCategory

pytestmark = pytest.mark.django_db


def create_activity(cat, sport, title="A"):
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title=title,
        difficulty=1,
        duration=60,
        base_price=10,
    )
    Slot.objects.create(
        sport=sport,
        activity=act,
        title="S",
        location="L",
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=5,
        price=0,
        rating=0,
    )
    return act


def test_filter_activities_by_category():
    client = APIClient()
    sport = Sport.objects.create(name="Surf")
    cat1 = Category.objects.create(name="Water")
    cat2 = Category.objects.create(name="Land")
    create_activity(cat1, sport, "A1")
    create_activity(cat2, sport, "A2")
    resp = client.get("/api/activities/", {"category": cat1.id})
    assert resp.status_code == 200
    assert all(a["discipline"] == cat1.id for a in resp.data["results"])


def test_filter_includes_descendants():
    client = APIClient()
    sport = Sport.objects.create(name="Run")
    cat = Category.objects.create(name="Parent")
    create_activity(cat, sport, "ParentAct")
    resp = client.get("/api/activities/", {"category": cat.id})
    assert resp.status_code == 200
    assert len(resp.data["results"]) == 1


def test_featured_categories_ordering():
    client = APIClient()
    cat = Category.objects.create(name="C")
    f1 = FeaturedCategory.objects.create(category=cat, image="a.jpg", display_order=2)
    f2 = FeaturedCategory.objects.create(category=cat, image="b.jpg", display_order=1)
    resp = client.get("/api/featured-categories/", {"home": "true"})
    assert resp.status_code == 200
    ids = [f["id"] for f in resp.data]
    assert ids == [f2.id, f1.id]
