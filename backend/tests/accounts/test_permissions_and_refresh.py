from django.test import TestCase, Client
from django.utils import timezone
from freezegun import freeze_time
from backend.tests.utils.factories import (
    vendor_factory,
    user_factory,
    activity_factory,
    facility_factory,
)

class AuthAndPermTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.vendor = vendor_factory()
        self.user = user_factory()
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

    def test_provider_only_endpoint(self):
        url = '/api/merchant/slots/'
        self.client.force_login(self.user)
        r = self.client.post(url, self.payload, content_type='application/json')
        self.assertEqual(r.status_code, 403)
        self.client.force_login(self.vendor.user)
        r2 = self.client.post(url, self.payload, content_type='application/json')
        self.assertEqual(r2.status_code, 201)

    def test_refresh_flow(self):
        login = self.client.post('/api/token/', {'username': self.user.username, 'password': 'pass1234'})
        tokens = login.json()
        access = tokens['access']; refresh = tokens['refresh']
        with freeze_time(timezone.now() + timezone.timedelta(days=1)):
            r1 = self.client.get('/api/facilities/', HTTP_AUTHORIZATION=f'Bearer {access}')
            self.assertEqual(r1.status_code, 401)
        r2 = self.client.post('/api/token/refresh/', {'refresh': refresh})
        self.assertEqual(r2.status_code, 200)
        new_access = r2.json()['access']
        r3 = self.client.get('/api/facilities/', HTTP_AUTHORIZATION=f'Bearer {new_access}')
        self.assertEqual(r3.status_code, 200)
