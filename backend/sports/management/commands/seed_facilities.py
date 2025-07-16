from django.core.management.base import BaseCommand
from django.contrib.gis.geos import Point
from random import sample, uniform
from backend.sports.models import Facility, Category


class Command(BaseCommand):
    help = "Seed demo Facility data"

    def handle(self, *args, **kwargs):
        Facility.objects.all().delete()
        categories = list(Category.objects.all())
        for idx in range(30):
            fac = Facility.objects.create(
                name=f"Facility {idx+1}",
                location=Point(uniform(-0.1, 0.1), uniform(-0.1, 0.1)),
                radius=1000,
            )
            fac.categories.set(sample(categories, k=min(len(categories), 3)))
        self.stdout.write(self.style.SUCCESS("Facilities seeded"))
