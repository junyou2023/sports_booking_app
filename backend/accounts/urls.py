from django.urls import path

from .views import (
    ProfileView,
    VendorArea,
    GoogleLoginView,
    MerchantSignupView,
    ProviderProfileView,
    OrganizationMemberView,
)

urlpatterns = [
    path("profile/", ProfileView.as_view()),
    path("me/", ProfileView.as_view()),
    path("vendor-area/", VendorArea.as_view()),
    path("auth/google/", GoogleLoginView.as_view()),
    path("provider/register/", MerchantSignupView.as_view()),
    path("provider/profile/", ProviderProfileView.as_view()),
    path(
        "organization/<slug:slug>/members/",
        OrganizationMemberView.as_view(),
    ),
]
