# sports/urls.py
from rest_framework.routers import DefaultRouter
from django.urls import path
from .views import (
    SportViewSet,
    SlotViewSet,
    BookingViewSet,
    CategoryViewSet,
    SportCategoryViewSet,
    FacilityViewSet,
    VariantViewSet,
    ActivityViewSet,
    FeaturedCategoryViewSet,
    FeaturedActivityViewSet,
    ActivityReviewList,
    BulkSlotCreateView,
    MerchantSlotCreateView,
    MerchantBookingList,
)

router = DefaultRouter()
router.register(r"sports",    SportViewSet,    basename="sport")
router.register(r"categories", CategoryViewSet, basename="category")
router.register(r"sport-categories", SportCategoryViewSet, basename="sportcategory")
router.register(r"variants",   VariantViewSet,  basename="variant")
router.register(r"activities", ActivityViewSet, basename="activity")
router.register(r"facilities", FacilityViewSet, basename="facility")
router.register(r"featured-categories", FeaturedCategoryViewSet, basename="featuredcategory")
router.register(r"featured-activities", FeaturedActivityViewSet, basename="featuredactivity")
router.register(r"slots",     SlotViewSet,     basename="slot")
router.register(r"bookings",  BookingViewSet,  basename="booking")
urlpatterns = router.urls + [
    path("slots/bulk/", BulkSlotCreateView.as_view(), name="slot-bulk"),
    path("merchant/slots/", MerchantSlotCreateView.as_view()),
    path("merchant/bookings/", MerchantBookingList.as_view()),
    path("activities/<int:activity_id>/reviews/", ActivityReviewList.as_view(), name="activity-reviews"),
]
