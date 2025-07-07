from django.core.management.base import BaseCommand
from backend.sports.models import Sport


class Command(BaseCommand):
    """
    Seeds six demo sports with placeholder banner images.
    Run:  python manage.py seed_sports
    """

    def handle(self, *args, **kwargs):
        Sport.objects.all().delete()
        rows = [
            ("Badminton", "https://picsum.photos/seed/badminton/600/400"),
            ("Bungee", "https://picsum.photos/seed/bungee/600/400"),
            ("Sailing", "https://picsum.photos/seed/sailing/600/400"),
            ("Cycling", "https://picsum.photos/seed/cycling/600/400"),
            ("Football", "https://picsum.photos/seed/football/600/400"),
            ("Kayaking", "https://picsum.photos/seed/kayaking/600/400"),
        ]
        for name, url in rows:
            Sport.objects.create(name=name, banner=url)

        self.stdout.write(self.style.SUCCESS(f"Seeded {len(rows)} sports"))
