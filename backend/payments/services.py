import os
import logging
import stripe

stripe.api_key = os.getenv('STRIPE_API_KEY', '')
logger = logging.getLogger(__name__)


def refund(booking):
    """Issue a refund via Stripe for the given booking."""
    if not booking.payment_intent_id:
        raise ValueError('booking has no payment intent')
    try:
        stripe.Refund.create(payment_intent=booking.payment_intent_id)
    except stripe.error.StripeError as e:  # pragma: no cover - network call
        logger.exception('Stripe refund failed')
        raise
