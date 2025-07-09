from rest_framework.permissions import BasePermission

class IsVendor(BasePermission):
    """Allows access only to users with a VendorProfile."""

    def has_permission(self, request, view):
        return request.user and hasattr(request.user, "vendorprofile")
