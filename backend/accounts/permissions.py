from rest_framework.permissions import BasePermission
from .models import OrganizationMember


class IsVendor(BasePermission):
    """Allow access to vendor users who belong to an organization."""

    def has_permission(self, request, view):
        user = request.user
        if not getattr(user, "is_vendor", False):
            return False
        return OrganizationMember.objects.filter(user=user).exists()
