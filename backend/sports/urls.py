# sports/urls.py
from rest_framework.routers import DefaultRouter
from .views import SportViewSet, SlotViewSet, BookingViewSet, MySlotViewSet

router = DefaultRouter()
router.register(r"sports", SportViewSet, basename="sport")
router.register(r"slots", SlotViewSet, basename="slot")
router.register(r"bookings", BookingViewSet, basename="booking")
router.register(r"my-slots", MySlotViewSet, basename="my-slot")

urlpatterns = router.urls
