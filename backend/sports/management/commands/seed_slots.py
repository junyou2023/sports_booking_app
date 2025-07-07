# sports/management/commands/seed_slots.py
"""
CLI usage:  python manage.py seed_slots
Seeds demo Slot rows for each Sport.
"""
import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone

# seed_slots.py
from backend.sports.models import Sport, Slot


class Command(BaseCommand):
    help = "Seed demo Slot data"

    def handle(self, *args, **kwargs):
        now = timezone.now().replace(minute=0, second=0, microsecond=0)
        Slot.objects.all().delete()

        for sport in Sport.objects.all():
            for day in range(5):  # next 5 days
                start = now + timedelta(days=day, hours=9)
                for idx in range(6):  # 6 slots / day
                    Slot.objects.create(
                        sport=sport,
                        title=f"{sport.name} Session {idx + 1}",
                        location="City Center",
                        begins_at=start + timedelta(hours=idx),
                        ends_at=start + timedelta(hours=idx + 1),
                        capacity=random.randint(6, 20),
                        price=round(random.uniform(20, 80), 2),
                        rating=round(random.uniform(3.5, 5.0), 1),
                    )
        self.stdout.write(self.style.SUCCESS("▶  Demo slots seeded"))
