import django
django.setup()
import pytest
from rest_framework.test import APIClient
from sports.models import Sport, Category, Activity, Facility
from django.contrib.gis.geos import Point

pytestmark = pytest.mark.django_db


@pytest.fixture
def client():
    return APIClient()


def create_data():
    sport1 = Sport.objects.create(name="Surf")
    sport2 = Sport.objects.create(name="Bike")
    cat1 = Category.objects.create(name="Water")
    cat2 = Category.objects.create(name="Land")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    Activity.objects.create(
        sport=sport1,
        discipline=cat1,
        organization=org,
        title="Surf Class",
        description="Learn surfing",
        difficulty=1,
        duration=60,
        base_price=0,
    )
    Activity.objects.create(
        sport=sport2,
        discipline=cat2,
        organization=org,
        title="Mountain Biking",
        description="Ride the hills",
        difficulty=1,
        duration=60,
        base_price=0,
    )
    Facility.objects.create(name="Surf Center", location=Point(0, 0))
    f2 = Facility.objects.create(name="Bike Hub", location=Point(0, 0))
    f2.categories.add(cat2)
    return sport1, sport2, cat1, cat2


def test_search_by_title(client):
    create_data()
    res = client.get("/api/activities/", {"q": "Surf"})
    assert res.data["count"] == 1
    assert res.data["results"][0]["title"] == "Surf Class"


def test_search_by_description(client):
    create_data()
    res = client.get("/api/activities/", {"q": "hills"})
    assert res.data["count"] == 1
    assert res.data["results"][0]["title"] == "Mountain Biking"


def test_search_by_sport_name(client):
    create_data()
    res = client.get("/api/activities/", {"q": "Surf"})
    assert res.data["count"] == 1


def test_search_category_filter(client):
    _, _, cat1, _ = create_data()
    res = client.get("/api/activities/", {"q": "Class", "category": cat1.id})
    assert res.data["count"] == 1


def test_search_no_match(client):
    create_data()
    res = client.get("/api/activities/", {"q": "Unknown"})
    assert res.data["count"] == 0


def test_search_pagination(client):
    sport = Sport.objects.create(name="Run")
    cat = Category.objects.create(name="Road")
    from accounts.models import Organization
    from uuid import uuid4
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    for i in range(25):
        Activity.objects.create(
            sport=sport,
            discipline=cat,
            organization=org,
            title=f"Run {i}",
            description="Long run",
            difficulty=1,
            duration=60,
            base_price=0,
        )
    res = client.get("/api/activities/", {"q": "Run", "page": 2})
    assert res.data["previous"] is not None
    assert res.data["count"] == 25


def test_facility_search_by_name(client):
    create_data()
    res = client.get("/api/facilities/", {"q": "Bike"})
    assert res.status_code == 200
    assert len(res.data) == 1 or res.data["count"] == 1


def test_facility_search_by_category(client):
    create_data()
    res = client.get("/api/facilities/", {"q": "Land"})
    assert len(res.data) == 1 or res.data["count"] == 1


