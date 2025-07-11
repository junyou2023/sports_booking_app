import django
import pytest
django.setup()
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from accounts.models import VendorProfile, CustomerProfile
pytestmark = pytest.mark.django_db

def test_registration_creates_profiles():
    client = APIClient()
    client.defaults["HTTP_HOST"] = "localhost"
    resp = client.post(
        "/api/auth/registration/",
        {
        "email": "demo_auth@example.com",
            "password1": "StrongPass123",
            "password2": "StrongPass123",
        },
        format="json",
    )
    assert resp.status_code == 201
    user = User.objects.get(email="demo_auth@example.com")
    assert VendorProfile.objects.filter(user=user).exists()
    assert CustomerProfile.objects.filter(user=user).exists()
    assert "access" in resp.data and "refresh" in resp.data
