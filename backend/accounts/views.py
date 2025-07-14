from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny

from .permissions import IsVendor
from rest_framework.response import Response

from .serializers import ProfileSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from allauth.socialaccount.models import SocialAccount
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = ProfileSerializer(request.user)
        return Response(serializer.data)


class VendorArea(APIView):
    """Example endpoint accessible only to vendor accounts."""

    permission_classes = [IsAuthenticated, IsVendor]

    def get(self, request):
        company = request.user.vendorprofile.company_name
        return Response({"company": company})


class GoogleLoginView(APIView):
    """Exchange Google ID token for JWT."""

    permission_classes = [AllowAny]

    def post(self, request):
        token = request.data.get("id_token")
        if not token:
            return Response({"detail": "Missing id_token"}, status=400)
        try:
            info = google_id_token.verify_oauth2_token(
                token, google_requests.Request()
            )
        except Exception:
            return Response({"detail": "Invalid id_token"}, status=400)

        email = info.get("email")
        if not email:
            return Response({"detail": "email not provided"}, status=400)

        user, _ = User.objects.get_or_create(
            username=email,
            defaults={"email": email},
        )
        SocialAccount.objects.get_or_create(
            user=user,
            provider="google",
            uid=info.get("sub"),
        )

        refresh = RefreshToken.for_user(user)
        return Response(
            {"access": str(refresh.access_token), "refresh": str(refresh)}
        )
