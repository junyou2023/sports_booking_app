# sports/urls.py
from rest_framework.routers import DefaultRouter
from .views import SportViewSet, SlotViewSet, BookingViewSet

router = DefaultRouter()
router.register(r"sports", SportViewSet, basename="sport")
router.register(r"slots", SlotViewSet, basename="slot")
router.register(r"bookings", BookingViewSet, basename="booking")

urlpatterns = router.urls
