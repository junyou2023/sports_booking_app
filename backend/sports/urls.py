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
    ContinuePlanningView,
    BulkSlotCreateView,
    MerchantBookingList,
    FavoriteViewSet,
)
from .merchant_views import MerchantSlotViewSet, MerchantSlotBulkDeleteView, MerchantBookingListPaged, MerchantBookingCancelView

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
router.register(r"favorites", FavoriteViewSet, basename="favorite")
router.register(r"merchant/slots", MerchantSlotViewSet, basename="merchant-slots")
urlpatterns = router.urls + [
    path("slots/bulk/", BulkSlotCreateView.as_view(), name="slot-bulk"),
    path("merchant/bookings/", MerchantBookingList.as_view()),
    path("merchant/bookings/paged/", MerchantBookingListPaged.as_view()),
    path("merchant/bookings/<int:pk>/cancel/", MerchantBookingCancelView.as_view()),
    path("merchant/slots/bulk-delete/", MerchantSlotBulkDeleteView.as_view()),
    path("activities/<int:activity_id>/reviews/", ActivityReviewList.as_view(), name="activity-reviews"),
    path("home/continue-planning/", ContinuePlanningView.as_view()),
]
