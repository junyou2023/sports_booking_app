from rest_framework.permissions import BasePermission
from .models import OrganizationMember, VendorProfile


class IsVendor(BasePermission):
    """Allows access only to users with a VendorProfile."""

    message = "You need a provider account to create facilities."

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return OrganizationMember.objects.filter(user=user).exists()


class IsOrgMember(BasePermission):
    """Allow access if user belongs to object's organization."""

    def has_object_permission(self, request, view, obj):
        org = getattr(obj, "organization", obj)
        return OrganizationMember.objects.filter(
            organization=org, user=request.user
        ).exists()


class IsOrgOwner(BasePermission):
    """Allow access only to organization owners."""

    def has_object_permission(self, request, view, obj):
        org = getattr(obj, "organization", obj)
        return OrganizationMember.objects.filter(
            organization=org, user=request.user, role="owner"
        ).exists()
