import json
import os
from unittest.mock import patch
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient
from sports.models import Booking
from backend.tests.utils.factories import user_factory, slot_factory
import stripe

User = get_user_model()

class StripeWebhookTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = user_factory()
        self.slot = slot_factory()
        self.booking = Booking.objects.create(
            slot=self.slot,
            activity=self.slot.activity,
            user=self.user,
            status='pending',
            paid=False,
            payment_intent_id='pi_test',
        )
        os.environ['STRIPE_WEBHOOK_SECRET'] = 'whsec_test'

    def _event(self, event_type):
        payload = {
            'type': event_type,
            'data': {'object': {'id': 'pi_test', 'metadata': {'slot_id': self.slot.id, 'user_id': self.user.id}}},
        }
        headers = {'HTTP_STRIPE_SIGNATURE': 't=1,v1=fake', 'CONTENT_TYPE': 'application/json'}
        return headers, json.dumps(payload)

    @patch('stripe.Webhook.construct_event')
    def test_success_confirms_once_and_duplicate_ignored(self, mock_construct):
        headers, payload = self._event('payment_intent.succeeded')
        mock_construct.return_value = json.loads(payload)
        r1 = self.client.post('/api/payments/webhook/', data=payload, **headers)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'confirmed')
        r2 = self.client.post('/api/payments/webhook/', data=payload, **headers)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'confirmed')
        self.assertEqual(r2.status_code, 200)

    @patch('stripe.Webhook.construct_event')
    def test_decline_stays_pending(self, mock_construct):
        headers, payload = self._event('payment_intent.payment_failed')
        mock_construct.return_value = json.loads(payload)
        r = self.client.post('/api/payments/webhook/', data=payload, **headers)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'pending')
        self.assertEqual(r.status_code, 200)

    @patch('stripe.Webhook.construct_event', side_effect=stripe.error.SignatureVerificationError('bad', 'sig'))
    def test_invalid_signature_400(self, mock_construct):
        headers, payload = self._event('payment_intent.succeeded')
        r = self.client.post('/api/payments/webhook/', data=payload, **headers)
        self.assertEqual(r.status_code, 400)
