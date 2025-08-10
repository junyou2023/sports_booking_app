from datetime import datetime, date
from typing import Union
from decimal import Decimal

from sports.models import PriceRule, Slot


def get_price(slot: Slot) -> Decimal:
    """Return the applicable price for a slot considering PriceRule.

    If multiple rules match, the most specific (shortest duration) is chosen.
    Ties are resolved by the latest created rule.
    """
    rules = PriceRule.objects.filter(
        activity=slot.activity,
        weekday=slot.begins_at.weekday(),
        time_start__lt=slot.ends_at.time(),
        time_end__gt=slot.begins_at.time(),
    )
    if not rules:
        return slot.price

    def duration(rule: PriceRule):
        start = datetime.combine(date.min, rule.time_start)
        end = datetime.combine(date.min, rule.time_end)
        return end - start

    best = sorted(rules, key=lambda r: (duration(r), -r.created_at.timestamp()))[0]
    return best.price
