import pytest
from rest_framework.test import APIClient
from backend.tests.utils.factories import user_factory

pytestmark = pytest.mark.django_db


def test_vendor_only_forbidden_for_normal_user():
    user = user_factory()
    client = APIClient(); client.force_authenticate(user=user)
    resp = client.post("/api/merchant/slots/", {"dummy": "x"}, format="json")
    assert resp.status_code == 403


@pytest.mark.skip(reason="JWT refresh flow not covered")
def test_jwt_refresh_then_retry_success():
    pass
