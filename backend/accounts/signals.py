from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User

from .models import CustomerProfile


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if not created:
        return
    # normal users get a CustomerProfile by default
    CustomerProfile.objects.get_or_create(user=instance)
