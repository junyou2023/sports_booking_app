import os
import logging
import stripe

stripe.api_key = os.getenv("STRIPE_API_KEY", "")
logger = logging.getLogger(__name__)


def refund(booking):
    """Attempt to refund a paid booking via Stripe.

    Raises ``stripe.error.StripeError`` on failure.
    """
    if not booking.payment_intent_id:
        raise ValueError("booking missing payment_intent_id")
    try:
        stripe.Refund.create(payment_intent=booking.payment_intent_id)
    except stripe.error.StripeError as e:
        logger.exception("Stripe refund failed")
        raise
