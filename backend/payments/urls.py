from django.urls import path
from .views import StripeCheckoutView

urlpatterns = [
    path('payments/checkout/', StripeCheckoutView.as_view()),
]
