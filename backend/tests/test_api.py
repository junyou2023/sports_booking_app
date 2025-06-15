import pytest
from django.urls import reverse
from rest_framework.test import APIClient

@pytest.mark.django_db
def test_get_sports_returns_200_and_json():
    """
    /api/sports/ must return HTTP 200 and a non-empty JSON list.
    """
    client = APIClient()
    url = reverse("sport-list")          # router basename + '-list'
    rsp = client.get(url)

    assert rsp.status_code == 200
    assert isinstance(rsp.json(), list)  # should be a JSON array
    assert len(rsp.json()) >= 6          # seeded 6 sports
