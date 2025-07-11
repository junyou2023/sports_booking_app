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

def test_profile_endpoint(client):
    user = User.objects.create_user("demo2", email="demo2@example.com", password="Pass12345")
    # profiles automatically created via signal
    user.vendorprofile.company_name = "ACME"
    user.vendorprofile.save()
    user.customerprofile.phone = "123456"
    user.customerprofile.save()
    client.force_authenticate(user)
    resp = client.get("/api/profile/")
    assert resp.status_code == 200
    assert resp.data["email"] == "demo2@example.com"
    assert resp.data["company_name"] == "ACME"
    assert resp.data["phone"] == "123456"

def test_token_refresh(client):
    user = User.objects.create_user("demo3", email="demo3@example.com", password="Pass12345")
    resp = client.post(
        "/api/token/",
        {"username": "demo3", "password": "Pass12345"},
    )
    assert resp.status_code == 200
    refresh = resp.data["refresh"]
    resp2 = client.post("/api/token/refresh/", {"refresh": refresh})
    assert resp2.status_code == 200
    assert "access" in resp2.data
