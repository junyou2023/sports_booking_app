import pytest
from rest_framework.test import APIClient
from backend.tests.utils.factories import facility_factory

try:
    from django.contrib.gis import gdal
    gdal.gdal_version()
    HAS_GDAL = True
except Exception:
    HAS_GDAL = False

pytestmark = pytest.mark.django_db


@pytest.mark.skipif(not HAS_GDAL, reason="PostGIS unavailable")
def test_nearby_radius_and_ordering():
    f1 = facility_factory(lat=0.0, lon=0.045)  # ~5km
    f2 = facility_factory(lat=0.0, lon=0.108)  # ~12km
    client = APIClient()
    resp = client.get("/api/facilities/", {"near": "0,0", "radius": 6000})
    assert resp.status_code == 200
    ids = [row["id"] for row in resp.json()]
    assert f1.id in ids and f2.id not in ids
    dists = [row["properties"]["distance_m"] for row in resp.json()]
    assert dists == sorted(dists)
