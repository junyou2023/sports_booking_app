from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model


class Command(BaseCommand):
    help = (
        "List users who have a VendorProfile and are marked as staff "
        "but are not superusers."
    )

    def handle(self, *args, **options):
        User = get_user_model()
        qs = User.objects.filter(
            vendorprofile__isnull=False, is_staff=True, is_superuser=False
        )
        for u in qs:
            self.stdout.write(f"{u.username}\t{u.email}\t{u.id}")
