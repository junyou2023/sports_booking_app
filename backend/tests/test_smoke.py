# backend/tests/test_smoke.py
import pytest
from django.urls import reverse


@pytest.mark.django_db
def test_sports_list(client):
    url = reverse("sport-list")  # 确保 router basename 是 sport
    resp = client.get(url)
    assert resp.status_code == 200
