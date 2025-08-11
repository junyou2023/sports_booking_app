from django.db import models
from django.contrib.auth.models import User
from django.conf import settings


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


class Organization(models.Model):
    name = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:  # pragma: no cover
        return self.name


class OrganizationMember(models.Model):
    ROLE_OWNER = "owner"
    ROLE_STAFF = "staff"
    ROLE_CHOICES = [(ROLE_OWNER, "Owner"), (ROLE_STAFF, "Staff")]
    organization = models.ForeignKey(
        Organization, related_name="members", on_delete=models.CASCADE
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="org_memberships",
        on_delete=models.CASCADE,
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    is_default = models.BooleanField(default=False)

    class Meta:
        unique_together = ("organization", "user")

    def __str__(self) -> str:  # pragma: no cover
        return f"{self.organization} - {self.user} ({self.role})"
