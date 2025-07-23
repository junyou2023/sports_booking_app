from django.urls import path
from .views import StripeCheckoutView, StripeWebhookView

urlpatterns = [
    path('payments/checkout/', StripeCheckoutView.as_view()),
    path('payments/webhook/', StripeWebhookView.as_view()),
]
