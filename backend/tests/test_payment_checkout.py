import django
import pytest
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from django.utils import timezone
from sports.models import Sport, Category, Activity, Slot, Booking
import stripe
from payments import views as pay_views

django.setup()
pytestmark = pytest.mark.django_db


@pytest.fixture
def auth_client():
    user = User.objects.create_user('u1', email='u1@example.com', password='pass')
    client = APIClient()
    client.force_authenticate(user)
    return client


@pytest.fixture
def slot():
    sport = Sport.objects.create(name='X')
    cat = Category.objects.create(name='C')
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        title='A',
        description='',
        difficulty=1,
        duration=60,
        base_price=10,
    )
    return Slot.objects.create(
        sport=sport,
        activity=act,
        title='S',
        location='L',
        begins_at=timezone.now() + timezone.timedelta(hours=1),
        ends_at=timezone.now() + timezone.timedelta(hours=2),
        capacity=5,
        price=10,
    )


def test_checkout_no_key_returns_500(auth_client, slot, monkeypatch):
    monkeypatch.setattr(pay_views.stripe, 'api_key', '')
    resp = auth_client.post('/api/payments/checkout/', {'slot': slot.id}, format='json')
    assert resp.status_code == 500
    assert 'misconfigured' in resp.data['detail']


def test_checkout_success_creates_booking(auth_client, slot, monkeypatch):
    class FakeIntent:
        id = 'pi_123'
        client_secret = 'sec'
    def fake_create(**kwargs):
        return FakeIntent()
    monkeypatch.setattr(pay_views.stripe.PaymentIntent, 'create', staticmethod(fake_create))
    resp = auth_client.post('/api/payments/checkout/', {'slot': slot.id}, format='json')
    assert resp.status_code == 200
    data = resp.data
    assert data['intent_id'] == 'pi_123'
    booking = Booking.objects.get(id=data['booking_id'])
    assert booking.slot == slot
    assert booking.status == 'pending'
    assert not booking.paid
