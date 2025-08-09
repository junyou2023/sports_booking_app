import pytest
import django
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from django.db import connection
from django.db.migrations.executor import MigrationExecutor

django.setup()


pytestmark = pytest.mark.django_db


def test_vendor_signup_not_staff():
    client = APIClient()
    res = client.post(
        "/api/provider/register/",
        {
            "email": "v1@example.com",
            "password1": "pass1234",
            "password2": "pass1234",
        },
    )
    assert res.status_code == 200
    user = User.objects.get(email="v1@example.com")
    assert not user.is_staff
    admin_resp = client.get("/admin/")
    assert admin_resp.status_code == 302


def test_org_default_migration():
    executor = MigrationExecutor(connection)
    old_target = [
        ("accounts", "0002_vendor_extra_fields"),
        ("sports", "0017_trigram_indexes"),
    ]
    executor.migrate(old_target)
    old_apps = executor.loader.project_state(old_target).apps
    UserModel = old_apps.get_model("auth", "User")
    Sport = old_apps.get_model("sports", "Sport")
    Category = old_apps.get_model("sports", "Category")
    Activity = old_apps.get_model("sports", "Activity")
    user = UserModel.objects.create_user("old", email="old@example.com", password="pass")
    sport = Sport.objects.create(name="S")
    cat = Category.objects.create(name="C")
    act_id = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title="A",
        owner=user,
        difficulty=1,
        duration=60,
        base_price=0,
    ).id
    executor = MigrationExecutor(connection)
    executor.migrate(executor.loader.graph.leaf_nodes())
    ActivityNew = executor.loader.project_state(None).apps.get_model(
        "sports", "Activity"
    )
    Organization = executor.loader.project_state(None).apps.get_model(
        "accounts", "Organization"
    )
    OrganizationMember = executor.loader.project_state(None).apps.get_model(
        "accounts", "OrganizationMember"
    )
    act = ActivityNew.objects.get(id=act_id)
    org = Organization.objects.get()
    member = OrganizationMember.objects.get()
    assert act.organization_id == org.id
    assert member.user_id == user.id and member.role == "owner"


def test_member_permissions():
    owner = User.objects.create_user("own", email="own@example.com", password="pass")
    staff = User.objects.create_user("stf", email="stf@example.com", password="pass")
    from accounts.models import Organization, OrganizationMember
    from uuid import uuid4

    org = Organization.objects.create(name="Org", slug=f"o-{uuid4().hex[:8]}")
    OrganizationMember.objects.create(organization=org, user=owner, role="owner")
    OrganizationMember.objects.create(organization=org, user=staff, role="staff")

    owner_client = APIClient()
    owner_client.force_authenticate(owner)
    staff_client = APIClient()
    staff_client.force_authenticate(staff)

    res = owner_client.post(
        f"/api/merchant/orgs/{org.id}/members/",
        {"user_id": staff.id, "role": "staff"},
    )
    assert res.status_code == 400  # duplicate

    res = staff_client.post(
        f"/api/merchant/orgs/{org.id}/members/",
        {"user_id": owner.id, "role": "staff"},
    )
    assert res.status_code == 403

    from sports.models import Sport, Category, Activity

    sport = Sport.objects.create(name="T")
    cat = Category.objects.create(name="C")
    act_res = staff_client.post(
        "/api/activities/",
        {
            "sport": sport.id,
            "discipline": cat.id,
            "title": "Test",
            "organization": org.id,
        },
    )
    assert act_res.status_code == 201

    member_id = OrganizationMember.objects.get(organization=org, user=staff).id
    res = owner_client.delete(
        f"/api/merchant/orgs/{org.id}/members/{member_id}/"
    )
    assert res.status_code == 204

    res = owner_client.delete(
        f"/api/merchant/orgs/{org.id}/members/{member_id}/"
    )
    assert res.status_code == 400
