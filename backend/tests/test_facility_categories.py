import pytest
from rest_framework.test import APIClient
from accounts.models import VendorProfile
from sports.models import Category


@pytest.fixture
def vendor_client(django_user_model):
    user = django_user_model.objects.create_user('v@example.com', 'v@example.com', 'pass')
    VendorProfile.objects.create(user=user)
    client = APIClient()
    token = client.post('/api/token/', {'email': 'v@example.com', 'password': 'pass'})
    access = token.data['access']
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
    return client


def test_facility_categories_int(vendor_client):
    c1 = Category.objects.create(name='Cat1')
    c2 = Category.objects.create(name='Cat2')
    resp = vendor_client.post('/api/facilities/', {
        'name': 'New',
        'lat': 1,
        'lng': 2,
        'radius': 1000,
        'categories': [c1.id, c2.id],
    })
    assert resp.status_code == 201


def test_facility_categories_str_invalid(vendor_client):
    Category.objects.create(name='Cat1')
    resp = vendor_client.post('/api/facilities/', {
        'name': 'Bad',
        'lat': 1,
        'lng': 2,
        'radius': 1000,
        'categories': ['1'],
    })
    assert resp.status_code == 400
