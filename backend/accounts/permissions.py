from rest_framework.permissions import BasePermission
from .models import OrganizationMember


class IsVendor(BasePermission):
    """Allows access only to users with a VendorProfile."""

    def has_permission(self, request, view):
        return request.user and hasattr(request.user, "vendorprofile")


class IsOrgMember(BasePermission):
    """Allow access if user belongs to object's organization."""

    def has_object_permission(self, request, view, obj):
        org = getattr(obj, "organization", None)
        if org is None and hasattr(obj, "activity"):
            org = getattr(obj.activity, "organization", None)
        if org is None:
            org = obj
        return OrganizationMember.objects.filter(
            organization=org, user=request.user
        ).exists()


class IsOrgOwner(BasePermission):
    """Allow access only to organization owners."""

    def has_object_permission(self, request, view, obj):
        org = getattr(obj, "organization", None)
        if org is None and hasattr(obj, "activity"):
            org = getattr(obj.activity, "organization", None)
        if org is None:
            org = obj
        return OrganizationMember.objects.filter(
            organization=org, user=request.user, role="owner"
        ).exists()
