import concurrent.futures
import pytest
from django.utils import timezone
from rest_framework.test import APIClient
from payments import views as pay_views
from backend.tests.utils.factories import user_factory, slot_factory

pytestmark = pytest.mark.django_db(transaction=True)

class FakeIntent:
    id = "pi_c"
    client_secret = "cs_c"


def test_concurrent_checkout_last_seat_one_wins(monkeypatch):
    slot = slot_factory(capacity=1, begins_at=timezone.now() + timezone.timedelta(hours=3))
    u1, u2 = user_factory(), user_factory()
    monkeypatch.setattr(pay_views.stripe, "api_key", "sk_test")
    monkeypatch.setattr(pay_views.stripe.PaymentIntent, "create", lambda **kw: FakeIntent())

    def do(u):
        c = APIClient(); c.force_authenticate(user=u)
        r = c.post("/api/payments/checkout/", {"slot": slot.id, "pax": 1}, format="json")
        return r.status_code

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
        r1 = ex.submit(do, u1); r2 = ex.submit(do, u2)
        results = {r1.result(), r2.result()}
    assert 200 in results and any(code in (400, 409) for code in results)
    slot.refresh_from_db()
    assert slot.current_participants == 1
