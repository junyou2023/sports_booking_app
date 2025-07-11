# backend/tests/test_smoke.py
import django
import pytest
from django.urls import reverse

django.setup()

@pytest.mark.django_db
def test_sports_list(client):
    url = reverse("sport-list")   # ensure router basename is sport
    resp = client.get(url)
    assert resp.status_code == 200
