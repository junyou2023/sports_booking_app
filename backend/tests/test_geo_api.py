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
from sports.models import Category, Facility, Slot  # noqa: E402
django.setup()
from django.contrib.gis.geos import Point
from django.utils import timezone
from rest_framework.test import APIClient
from sports.models import Category, Facility, Slot

pytestmark = [pytest.mark.django_db]


def setup_data():
    c1 = Category.objects.create(name="滑板")
    c2 = Category.objects.create(name="冲浪")
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
        title="Morning",
        location="loc",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
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
            "categories": "滑板,冲浪",
        },
    )
    assert resp.status_code == 200
    ids = [row["id"] for row in resp.data]
    assert ids == [f1.id]


def test_slots_by_facility():
    c1, c2, f1, f2 = setup_data()
    slot = f1.slots.first()
    resp = APIClient().get("/api/slots/", {"facility_id": f1.id})
    assert resp.status_code == 200
    assert resp.data[0]["id"] == slot.id
