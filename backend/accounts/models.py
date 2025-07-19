from django.db import models
from django.contrib.auth.models import User


class VendorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    company_name = models.CharField(max_length=100, blank=True)
    logo = models.URLField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.CharField(max_length=200, blank=True)

    class Meta:
        app_label = "accounts"

    def __str__(self) -> str:
        return self.company_name or self.user.username


class CustomerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=20, blank=True)

    class Meta:
        app_label = "accounts"

    def __str__(self) -> str:
        return self.user.username


# expose a convenience property on Django's User
def _user_is_provider(self) -> bool:
    return hasattr(self, "vendorprofile")


User.add_to_class("is_provider", property(_user_is_provider))
