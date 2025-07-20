from django.core.management.base import BaseCommand
from sports.models import Category, Variant

class Command(BaseCommand):
    help = "Seed demo Category and Variant data"

    def handle(self, *args, **options):
        Category.objects.all().delete()
        Variant.objects.all().delete()
        data = {
            "Watersports": ["Beginner", "Intermediate", "Advanced"],
            "Ball Sports": ["Indoor", "Outdoor"],
            "Fitness": ["HIIT", "Yoga"],
            "Adventure": ["Mountain", "Urban"],
        }
        for name, variants in data.items():
            cat = Category.objects.create(name=name)
            for v in variants:
                Variant.objects.create(discipline=cat, name=v)
        self.stdout.write(self.style.SUCCESS("Seeded taxonomy"))
