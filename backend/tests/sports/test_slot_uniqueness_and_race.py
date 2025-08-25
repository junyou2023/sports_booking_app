from django.test import TestCase
from rest_framework.test import APIClient
from django.utils import timezone
from backend.tests.utils.factories import (
    vendor_factory,
    activity_factory,
    facility_factory,
    slot_factory,
    user_factory,
)
from sports.models import Booking

class SlotRulesTests(TestCase):
    def setUp(self):
        self.vendor = vendor_factory()
        self.client = APIClient()
        self.client.force_login(self.vendor.user)
        self.activity = activity_factory(organization=self.vendor.org)
        self.facility = facility_factory(owner=self.vendor.user)
        begins = timezone.now() + timezone.timedelta(hours=1)
        ends = begins + timezone.timedelta(hours=1)
        self.payload = {
            'activity': self.activity.id,
            'facility': self.facility.id,
            'begins_at': begins.isoformat(),
            'ends_at': ends.isoformat(),
            'capacity': 1,
            'price': '9.99',
            'title': 'Slot',
            'location': 'Loc',
        }

    def test_duplicate_slot_rejected(self):
        url = '/api/merchant/slots/'
        r1 = self.client.post(url, self.payload, content_type='application/json')
        self.assertEqual(r1.status_code, 201)
        r2 = self.client.post(url, self.payload, content_type='application/json')
        self.assertEqual(r2.status_code, 400)

    def test_last_seat_race_single_confirmation(self):
        slot = slot_factory(activity=self.activity, capacity=1)
        user1 = user_factory()
        user2 = user_factory()
        c1 = APIClient(); c1.force_login(user1)
        c2 = APIClient(); c2.force_login(user2)
        data = {'slot': slot.id, 'pax': 1}
        r1 = c1.post('/api/bookings/', data, content_type='application/json')
        r2 = c2.post('/api/bookings/', data, content_type='application/json')
        statuses = {r1.status_code, r2.status_code}
        self.assertIn(201, statuses)
        self.assertIn(400, statuses)
        self.assertEqual(Booking.objects.filter(slot=slot).count(), 1)
