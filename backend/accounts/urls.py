from django.urls import path

from .views import ProfileView, VendorArea

urlpatterns = [
    path("profile/", ProfileView.as_view()),
    path("vendor-area/", VendorArea.as_view()),
]
