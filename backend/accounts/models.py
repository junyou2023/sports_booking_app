from django.db import models
from django.contrib.auth.models import User


# extend core User with vendor flag
User.add_to_class(
    "is_vendor",
    models.BooleanField(default=False, db_index=True),
)


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


class Organization(models.Model):
    name = models.CharField(max_length=120)
    slug = models.SlugField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)


class OrganizationMember(models.Model):
    ORGANIZATION_ROLES = (("owner", "Owner"), ("staff", "Staff"))
    organization = models.ForeignKey(
        Organization,
        on_delete=models.CASCADE,
        related_name="members",
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="orgs",
    )
    role = models.CharField(max_length=10, choices=ORGANIZATION_ROLES)


# expose a convenience property on Django's User
def _user_is_provider(self) -> bool:
    return hasattr(self, "vendorprofile")


User.add_to_class("is_provider", property(_user_is_provider))
