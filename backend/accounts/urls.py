from django.urls import path

from .views import (
    ProfileView,
    VendorArea,
    GoogleLoginView,
    ProviderRegisterView,
    ProviderProfileView,
)

urlpatterns = [
    path("profile/", ProfileView.as_view()),
    path("me/", ProfileView.as_view()),
    path("vendor-area/", VendorArea.as_view()),
    path("auth/google/", GoogleLoginView.as_view()),
    path("provider/register/", ProviderRegisterView.as_view()),
    path("provider/profile/", ProviderProfileView.as_view()),
]
