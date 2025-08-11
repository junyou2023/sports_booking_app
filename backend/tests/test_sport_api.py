import pytest
from rest_framework.test import APIClient
from accounts.models import VendorProfile
from sports.models import Sport


@pytest.fixture
def vendor_client(django_user_model):
    user = django_user_model.objects.create_user('v@example.com', 'v@example.com', 'pass')
    VendorProfile.objects.create(user=user)
    client = APIClient()
    token = client.post('/api/token/', {'email': 'v@example.com', 'password': 'pass'})
    access = token.data['access']
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
    return client


@pytest.fixture
def user_client(django_user_model):
    user = django_user_model.objects.create_user('u@example.com', 'u@example.com', 'pass')
    client = APIClient()
    token = client.post('/api/token/', {'email': 'u@example.com', 'password': 'pass'})
    access = token.data['access']
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
    return client


@pytest.fixture
def admin_client(django_user_model):
    user = django_user_model.objects.create_superuser('a@example.com', 'a@example.com', 'pass')
    client = APIClient()
    token = client.post('/api/token/', {'email': 'a@example.com', 'password': 'pass'})
    access = token.data['access']
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
    return client


def test_vendor_can_create_sport(vendor_client):
    resp = vendor_client.post('/api/sports/', {'name': 'Tennis'})
    assert resp.status_code == 201


def test_non_vendor_cannot_create_sport(user_client):
    resp = user_client.post('/api/sports/', {'name': 'Badminton'})
    assert resp.status_code == 403


def test_anonymous_cannot_create_sport():
    resp = APIClient().post('/api/sports/', {'name': 'Soccer'})
    assert resp.status_code == 403


def test_admin_crud_sport(admin_client):
    resp = admin_client.post('/api/sports/', {'name': 'Basketball'})
    assert resp.status_code == 201
    sport_id = resp.data['id']

    resp = admin_client.patch(f'/api/sports/{sport_id}/', {'description': 'team sport'})
    assert resp.status_code == 200

    resp = admin_client.delete(f'/api/sports/{sport_id}/')
    assert resp.status_code == 204
    assert not Sport.objects.filter(id=sport_id).exists()
