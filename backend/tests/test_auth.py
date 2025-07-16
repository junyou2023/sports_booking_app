import django
import pytest
from rest_framework.test import APIClient
import jwt
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken
from django.contrib.auth.models import User
from backend.accounts.models import VendorProfile, CustomerProfile

django.setup()
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
    user = User.objects.create_user(
        "demo2",
        email="demo2@example.com",
        password="Pass12345",
    )
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
    User.objects.create_user(
        "demo3",
        email="demo3@example.com",
        password="Pass12345",
    )
    resp = client.post(
        "/api/token/",
        {"username": "demo3", "password": "Pass12345"},
    )
    assert resp.status_code == 200
    refresh = resp.data["refresh"]
    resp2 = client.post("/api/token/refresh/", {"refresh": refresh})
    assert resp2.status_code == 200
    assert "access" in resp2.data


def test_logout_blacklists_token(client):
    resp = client.post(
        "/api/auth/registration/",
        {
            "email": "logout@example.com",
            "password1": "StrongPass123",
            "password2": "StrongPass123",
        },
        format="json",
    )
    refresh = resp.data["refresh"]
    access = resp.data["access"]
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    resp2 = client.post("/api/auth/logout/", {"refresh": refresh})
    assert resp2.status_code == 200
    jti = jwt.decode(
        refresh,
        options={"verify_signature": False},
    )["jti"]
    assert BlacklistedToken.objects.filter(token__jti=jti).exists()


def test_vendor_permission(client):
    user = User.objects.create_user(
        "v1",
        email="v1@e.com",
        password="Pass12345",
    )
    user.vendorprofile.company_name = "ACME"
    user.vendorprofile.save()
    client.force_authenticate(user)
    resp = client.get("/api/vendor-area/")
    assert resp.status_code == 200
    client.force_authenticate(None)

    user2 = User.objects.create_user(
        "c1",
        email="c1@e.com",
        password="Pass12345",
    )
    user2.vendorprofile.delete()
    user2 = User.objects.get(pk=user2.pk)
    client.force_authenticate(user2)
    resp2 = client.get("/api/vendor-area/")
    assert resp2.status_code == 403


def test_google_login(client, monkeypatch):
    def fake_verify(token, request):
        return {"email": "g@example.com", "sub": "123"}

    from accounts import views as account_views

    monkeypatch.setattr(
        account_views.google_id_token, "verify_oauth2_token", fake_verify
    )

    resp = client.post("/api/auth/google/", {"id_token": "dummy"})
    assert resp.status_code == 200
    assert "access" in resp.data and "refresh" in resp.data
    user = User.objects.get(email="g@example.com")
    from allauth.socialaccount.models import SocialAccount

    assert SocialAccount.objects.filter(user=user, provider="google").exists()


def test_registration_sends_email():
    from django.core import mail
    client = APIClient()
    client.post(
        "/api/auth/registration/",
        {
            "email": "verify@example.com",
            "password1": "StrongPass123",
            "password2": "StrongPass123",
        },
        format="json",
    )
    assert len(mail.outbox) == 1


def test_password_reset_sends_email():
    from django.core import mail
    User.objects.create_user(
        "u1",
        email="u1@example.com",
        password="pass12345",
    )
    client = APIClient()
    resp = client.post(
        "/api/auth/password/reset/",
        {"email": "u1@example.com"},
        format="json",
    )
    assert resp.status_code == 200
    assert len(mail.outbox) == 1
