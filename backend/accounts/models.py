from django.db import models
from django.contrib.auth.models import User


class VendorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    company_name = models.CharField(max_length=100, blank=True)

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
