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
from sports.models import Category, Facility, Slot, Activity, Sport  # noqa: E402

pytestmark = [pytest.mark.django_db]


def setup_data():
    c1 = Category.objects.create(name="Skateboard")
    c2 = Category.objects.create(name="Surfing")
    f1 = Facility.objects.create(name="A", location=Point(0, 0), radius=1000)
    f1.categories.add(c1, c2)
    f2 = Facility.objects.create(
        name="B",
        location=Point(0.01, 0),
        radius=1000,
    )
    f2.categories.add(c1)
    sport = Sport.objects.create(name="Surf")
    act = Activity.objects.create(
        sport=sport,
        discipline=c1,
        title="Act",
        description="",
        difficulty=1,
        duration=60,
        base_price=0,
        organization=None,
    )
    Slot.objects.create(
        facility=f1,
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
    items = resp.data.get("results", resp.data)
    if isinstance(items, dict) and "features" in items:
        items = items["features"]
    assert len(items) == 24


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
    ids = [row["id"] for row in resp.data["features"]]
    assert ids == [f1.id]


def test_slots_by_facility():
    c1, c2, f1, f2 = setup_data()
    slot = f1.slots.first()
    resp = APIClient().get("/api/slots/", {"facility_id": f1.id})
    assert resp.status_code == 200
    items = resp.data.get("results", resp.data)
    if isinstance(items, dict) and "features" in items:
        items = items["features"]
    first = items[0]
    if isinstance(first, dict) and "id" in first:
        first_id = first["id"]
    else:
        first_id = first.get("id")
    assert first_id == slot.id


def test_create_facility(django_user_model):
    user = django_user_model.objects.create_user(
        "m@example.com", "m@example.com", "pass"
    )
    from accounts.models import VendorProfile
    # Signal creates VendorProfile automatically; ensure one exists without
    # violating the one-to-one constraint.
    VendorProfile.objects.get_or_create(user=user)
    client = APIClient()
    token_res = client.post(
        "/api/token/", {"email": "m@example.com", "password": "pass"}
    )
    assert token_res.status_code == 200
    access = token_res.data["access"]
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
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
    assert resp.status_code == 201
    from sports.models import Facility
    facility = Facility.objects.get(name="New")
    assert facility.owner == user


# ---------------------------------------------------------------------------
# New tests for location-based search
# ---------------------------------------------------------------------------


def _seed_facilities():
    f1 = Facility.objects.create(name="A", location=Point(0, 0))
    f2 = Facility.objects.create(name="B", location=Point(0.02, 0))
    f3 = Facility.objects.create(name="C", location=Point(1, 1))
    return f1, f2, f3


def test_facilities_near_filter_ordering():
    f1, f2, f3 = _seed_facilities()
    resp = APIClient().get("/api/facilities/", {"near": "0,0", "radius": 3000})
    features = resp.data["features"]
    ids = [row["id"] for row in features]
    assert ids == [f1.id, f2.id]
    dists = [row["properties"]["distance_m"] for row in features]
    assert dists == sorted(dists)
    assert all(isinstance(d, int) for d in dists)


def test_facilities_distance_field_absent_without_near():
    _seed_facilities()
    resp = APIClient().get("/api/facilities/")
    assert "distance_m" not in resp.data["features"][0]["properties"]


def test_facilities_invalid_near_graceful():
    _seed_facilities()
    resp = APIClient().get("/api/facilities/", {"near": "abc"})
    assert len(resp.data["features"]) == 3
    assert "distance_m" not in resp.data["features"][0]["properties"]


def test_activities_near_and_nearby_priority():
    sport = Sport.objects.create(name="Tennis")
    cat = Category.objects.create(name="Court")
    f1, f2, f3 = _seed_facilities()
    act_near = Activity.objects.create(sport=sport, discipline=cat, title="Near")
    act_far = Activity.objects.create(
        sport=sport, discipline=cat, title="Far", is_nearby=True
    )
    Slot.objects.create(
        facility=f1,
        activity=act_near,
        title="S1",
        location="loc",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
        price=1,
    )
    Slot.objects.create(
        facility=f3,
        activity=act_far,
        title="S2",
        location="loc",
        begins_at=timezone.now(),
        ends_at=timezone.now() + timezone.timedelta(hours=1),
        capacity=5,
        price=1,
    )

    client = APIClient()
    resp = client.get("/api/activities/", {"near": "0,0", "radius": 3000})
    items = resp.data.get("results", resp.data)
    if isinstance(items, dict) and "features" in items:
        items = items["features"]
    ids = [row["id"] for row in items]
    assert ids == [act_near.id]
    assert isinstance(items[0]["distance_m"], int)

    resp = client.get(
        "/api/activities/", {"near": "0,0", "nearby": 1}
    )
    items = resp.data.get("results", resp.data)
    if isinstance(items, dict) and "features" in items:
        items = items["features"]
    ids = [row["id"] for row in items]
    assert ids == [act_far.id]
    assert "distance_m" not in items[0]
