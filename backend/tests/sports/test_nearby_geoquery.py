from django.test import TestCase, Client
from backend.tests.utils.factories import facility_factory

class NearbyQueryTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.near = facility_factory(lat=55.8721, lon=-4.2890)
        self.far = facility_factory(lat=55.9533, lon=-3.1883)

    def test_radius_filter(self):
        url = '/api/facilities/'
        response = self.client.get(f'{url}?near=55.8721,-4.2890&radius=10000')
        self.assertEqual(response.status_code, 200)
        features = response.json()['features']
        ids = [f['id'] for f in features]
        self.assertIn(self.near.id, ids)
        self.assertNotIn(self.far.id, ids)
