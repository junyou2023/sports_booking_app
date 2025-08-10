import json
from uuid import uuid4

import pytest
import pytest
from uuid import uuid4
from django.utils import timezone
from django.core.management import call_command
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from django.db import models

from sports.models import Booking, Sport, Category, Activity, Slot
from accounts.models import Organization

pytestmark = pytest.mark.django_db


def test_paged_list_cursor_filters(auth_client, slot):
    for i in range(55):
        u = User.objects.create_user(f'u{i}')
        Booking.objects.create(slot=slot, activity=slot.activity, user=u)
    u = User.objects.create_user('paid')
    Booking.objects.create(slot=slot, activity=slot.activity, user=u, status='confirmed', paid=True)

    resp = auth_client.get('/api/merchant/bookings/paged/')
    assert resp.status_code == 200
    assert len(resp.data['results']) == 50
    assert resp.data['next']

    resp = auth_client.get('/api/merchant/bookings/paged/?status=confirmed&paid=true')
    assert len(resp.data['results']) == 1
    assert resp.data['results'][0]['status'] == 'confirmed'

    resp_old = auth_client.get('/api/merchant/bookings/')
    assert len(resp_old.data) == 56


def test_cancel_pending_and_confirmed(auth_client, slot):
    u1 = User.objects.create_user('b1')
    b1 = Booking.objects.create(slot=slot, activity=slot.activity, user=u1, status='pending')
    u2 = User.objects.create_user('b2')
    b2 = Booking.objects.create(slot=slot, activity=slot.activity, user=u2, status='confirmed')
    r1 = auth_client.post(f'/api/merchant/bookings/{b1.id}/cancel/')
    b1.refresh_from_db()
    assert r1.status_code == 200
    assert b1.status == 'cancelled'
    r2 = auth_client.post(f'/api/merchant/bookings/{b2.id}/cancel/')
    b2.refresh_from_db()
    assert r2.status_code == 200
    assert b2.status == 'cancelled'
    u3 = User.objects.create_user('b3')
    b3 = Booking.objects.create(slot=slot, activity=slot.activity, user=u3, status='completed')
    r3 = auth_client.post(f'/api/merchant/bookings/{b3.id}/cancel/')
    assert r3.status_code == 400


def test_refund_success_and_failure(auth_client, slot, monkeypatch):
    u1 = User.objects.create_user('r1')
    b1 = Booking.objects.create(
        slot=slot, activity=slot.activity, user=u1,
        status='confirmed', paid=True, payment_intent_id='pi_1'
    )
    from payments import services as pay_services
    monkeypatch.setattr(pay_services, 'refund', lambda b: None)
    resp = auth_client.post(f'/api/merchant/bookings/{b1.id}/cancel/')
    b1.refresh_from_db()
    assert resp.status_code == 200
    assert b1.status == 'refunded'

    u2 = User.objects.create_user('r2')
    b2 = Booking.objects.create(
        slot=slot, activity=slot.activity, user=u2,
        status='confirmed', paid=True, payment_intent_id='pi_2'
    )
    def fail(_):
        raise Exception('boom')
    monkeypatch.setattr(pay_services, 'refund', fail)
    resp = auth_client.post(f'/api/merchant/bookings/{b2.id}/cancel/')
    b2.refresh_from_db()
    assert resp.status_code == 502
    assert b2.status == 'confirmed'


def test_timeout_job_or_command(slot):
    user = User.objects.create_user('t')
    b = Booking.objects.create(
        slot=slot,
        activity=slot.activity,
        user=user,
        status='pending',
        booked_at=timezone.now() - timezone.timedelta(minutes=31),
    )
    call_command('bookings_cancel_timeouts')
    b.refresh_from_db()
    assert b.status == 'cancelled'


def test_concurrency_unchanged(db):
    user1 = User.objects.create_user('u1')
    user2 = User.objects.create_user('u2')
    sport = Sport.objects.create(name='Swim')
    cat = Category.objects.create(name='C3')
    org = Organization.objects.create(name='O', slug=f'o-{uuid4().hex[:8]}')
    act = Activity.objects.create(
        sport=sport,
        discipline=cat,
        organization=org,
        title='A',
        description='',
        difficulty=1,
        duration=60,
        base_price=0,
    )
    slot = Slot.objects.create(
        sport=sport,
        activity=act,
        title='S',
        location='L',
        begins_at=timezone.now() + timezone.timedelta(minutes=1),
        ends_at=timezone.now() + timezone.timedelta(hours=1, minutes=1),
        capacity=1,
        price=0,
    )
    c1 = APIClient(); c1.force_authenticate(user1)
    c2 = APIClient(); c2.force_authenticate(user2)
    r1 = c1.post('/api/bookings/', {'slot_id': slot.id, 'pax': 1})
    r2 = c2.post('/api/bookings/', {'slot_id': slot.id, 'pax': 1})
    assert [r1.status_code, r2.status_code].count(201) == 1
    total = Booking.objects.filter(slot=slot).aggregate(models.Sum('pax'))['pax__sum']
    assert total <= slot.capacity
