"""
URL configuration for PlayNexus project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from dj_rest_auth.registration.views import RegisterView
from django.http import HttpResponse
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path("healthz", lambda r: JsonResponse({"status": "ok"})),
    path("admin/", admin.site.urls),
    path("api/", include("sports.urls")),          # ← REST entrance
    path("api/", include("accounts.urls")),        # profile endpoint
    path("api/", include("payments.urls")),
    path("api/auth/", include("dj_rest_auth.urls")),
    path("api/auth/register/", RegisterView.as_view()),
    path(
        "api/auth/registration/",
        include("dj_rest_auth.registration.urls"),
    ),
    path(
        "api/token/",
        TokenObtainPairView.as_view(),
        name="token_obtain_pair",
    ),
    path(
        "api/token/refresh/",
        TokenRefreshView.as_view(),
        name="token_refresh",
    ),
    path(
        "api/auth/token/refresh/",
        TokenRefreshView.as_view(),
    ),
    path(
        "password-reset-confirm/<uidb64>/<token>/",
        lambda r, uidb64, token: HttpResponse(""),
        name="password_reset_confirm",
    ),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
