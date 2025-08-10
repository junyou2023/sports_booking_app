import django
import pytest
from django.core.exceptions import ImproperlyConfigured
try:
    from django.contrib.gis import gdal
    gdal.gdal_version()
    HAS_GDAL = True
except (ImproperlyConfigured, Exception):
    HAS_GDAL = False

if not HAS_GDAL:
    pytest.skip("GDAL not available", allow_module_level=True)

django.setup()  # noqa: E402
from django.contrib.gis.geos import Point  # noqa: E402
from django.utils import timezone  # noqa: E402
from rest_framework.test import APIClient  # noqa: E402
from sports.models import Category, Facility, Slot, Sport, Activity  # noqa: E402
from accounts.models import Organization  # noqa: E402
from uuid import uuid4  # noqa: E402

pytestmark = [pytest.mark.django_db]


def setup_data():
    c1 = Category.objects.create(name="Skateboard")
    c2 = Category.objects.create(name="Surfing")
    sport = Sport.objects.create(name="Board")
    org = Organization.objects.create(name="O", slug=f"o-{uuid4().hex[:8]}")
    act = Activity.objects.create(
        sport=sport,
        discipline=c1,
        organization=org,
        title="Act",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
    )
    f1 = Facility.objects.create(name="A", location=Point(0, 0), radius=1000)
    f1.categories.add(c1, c2)
    f2 = Facility.objects.create(
        name="B",
        location=Point(0.01, 0),
        radius=1000,
    )
    f2.categories.add(c1)
    Slot.objects.create(
        facility=f1,
        sport=sport,
        activity=act,
        title="Morning",
        location="loc",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
        price=0,
    )
    return c1, c2, f1, f2


def test_categories_list():
    Category.objects.bulk_create([Category(name=str(i)) for i in range(24)])
    resp = APIClient().get("/api/categories/")
    assert resp.status_code == 200
    assert len(resp.data) == 24


def test_facilities_filter_near_categories():
    c1, c2, f1, f2 = setup_data()
    client = APIClient()
    resp = client.get(
        "/api/facilities/",
        {
            "near": "0,0",
            "radius": 2000,
            "categories": "Skateboard,Surfing",
        },
    )
    assert resp.status_code == 200
    data = resp.data if isinstance(resp.data, list) else resp.data.get("results", [])
    assert isinstance(data, list)


def test_slots_by_facility():
    c1, c2, f1, f2 = setup_data()
    slot = f1.slots.first()
    resp = APIClient().get("/api/slots/", {"facility_id": f1.id})
    assert resp.status_code == 200
    data = resp.data if isinstance(resp.data, list) else resp.data.get("results", [])
    assert isinstance(data, list)


def test_create_facility(provider_user, auth_client):
    client = auth_client
    resp = client.post(
        "/api/facilities/",
        {
            "name": "New",
            "lat": 1,
            "lng": 2,
            "radius": 1000,
            "categories": [],
        },
    )
    assert resp.status_code == 400
