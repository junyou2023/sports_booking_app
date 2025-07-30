import logging
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from .models import Booking, Notification
from .push import push_to_user

logger = logging.getLogger(__name__)

@receiver(post_save, sender=Booking)
def booking_created(sender, instance, created, **kwargs):
    if not created:
        return
    notif = Notification.objects.create(
        user=instance.user,
        ntype="booking_created",
        title="Booking created",
        body=f"Your booking for {instance.slot.title} was created.",
        data={"booking_id": instance.id},
    )
    push_to_user(instance.user, notif.title, notif.body, {"booking_id": instance.id})
    logger.info("Notification created for booking %s", instance.id)

@receiver(pre_save, sender=Booking)
def booking_status_changed(sender, instance, **kwargs):
    if not instance.pk:
        return
    try:
        previous = Booking.objects.get(pk=instance.pk)
    except Booking.DoesNotExist:
        return
    if previous.status != instance.status:
        notif = Notification.objects.create(
            user=instance.user,
            ntype="booking_updated",
            title="Booking updated",
            body=f"Status changed to {instance.status}",
            data={"booking_id": instance.id, "status": instance.status},
        )
        push_to_user(instance.user, notif.title, notif.body, {"booking_id": instance.id, "status": instance.status})
        logger.info("Notification created for booking %s status", instance.id)
