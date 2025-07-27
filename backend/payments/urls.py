from django.urls import path
from .views import StripeCheckoutView, StripeWebhookView, StripeConfirmView

urlpatterns = [
    path('payments/checkout/', StripeCheckoutView.as_view()),
    path('payments/webhook/', StripeWebhookView.as_view()),
    path('payments/confirm/<str:intent_id>/', StripeConfirmView.as_view()),
]
