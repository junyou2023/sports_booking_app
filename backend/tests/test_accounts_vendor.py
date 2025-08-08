import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken


@pytest.mark.django_db
class TestMerchantSignup:
    def test_signup_sets_vendor_and_no_admin_access(self):
        client = APIClient()
        data = {
            "email": "vendor@example.com",
            "password1": "pass1234",
            "password2": "pass1234",
            "company_name": "Vend Co",
        }
        resp = client.post("/api/provider/register/", data, format="json")
        assert resp.status_code == 200
        user = User.objects.get(email="vendor@example.com")
        assert user.is_vendor is True
        assert user.is_staff is False
        token = resp.data["access"]
        resp_admin = client.get(
            "/admin/", HTTP_AUTHORIZATION=f"Bearer {token}", follow=False
        )
        assert resp_admin.status_code == 302
        assert "/admin/login" in resp_admin.headers["Location"]


@pytest.mark.django_db
class TestOrganizationMembers:
    def setup_owner(self):
        client = APIClient()
        data = {
            "email": "owner@example.com",
            "password1": "pass1234",
            "password2": "pass1234",
            "company_name": "Owner Co",
        }
        resp = client.post("/api/provider/register/", data, format="json")
        token = resp.data["access"]
        user = User.objects.get(email="owner@example.com")
        org = user.orgs.first().organization
        return client, user, org, token

    def test_owner_and_staff_permissions(self):
        client, owner, org, token = self.setup_owner()
        staff_user = User.objects.create_user(
            username="staff@example.com",
            email="staff@example.com",
            password="pass1234",
        )
        resp = client.post(
            f"/api/organization/{org.slug}/members/",
            {"email": staff_user.email},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {token}",
        )
        assert resp.status_code == 201
        # staff member token
        refresh = RefreshToken.for_user(staff_user)
        staff_token = str(refresh.access_token)
        resp2 = client.post(
            f"/api/organization/{org.slug}/members/",
            {"email": "another@example.com"},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {staff_token}",
        )
        assert resp2.status_code == 403
        resp3 = client.delete(
            f"/api/organization/{org.slug}/members/",
            {"user": staff_user.id},
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {token}",
        )
        assert resp3.status_code == 204
