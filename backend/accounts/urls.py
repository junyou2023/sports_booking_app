from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    ProfileView,
    VendorArea,
    GoogleLoginView,
    ProviderRegisterView,
    ProviderProfileView,
    OrganizationMemberViewSet,
    MyOrganizationsView,
)

router = DefaultRouter()
router.register(
    r"merchant/orgs/(?P<org_id>\d+)/members",
    OrganizationMemberViewSet,
    basename="org-members",
)

urlpatterns = [
    path("profile/", ProfileView.as_view()),
    path("me/", ProfileView.as_view()),
    path("vendor-area/", VendorArea.as_view()),
    path("auth/google/", GoogleLoginView.as_view()),
    path("provider/register/", ProviderRegisterView.as_view()),
    path("provider/profile/", ProviderProfileView.as_view()),
    path("merchant/orgs/me/", MyOrganizationsView.as_view()),
]

urlpatterns += router.urls
