from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import viewsets, status
from django.shortcuts import get_object_or_404

from .permissions import IsVendor, IsOrgMember, IsOrgOwner
from rest_framework.response import Response

from .serializers import ProfileSerializer, ProviderRegisterSerializer
from .models import Organization, OrganizationMember
from drf_spectacular.utils import extend_schema
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


class ProviderRegisterView(APIView):
    """Register a new provider account."""

    permission_classes = [AllowAny]

    def post(self, request):
        ser = ProviderRegisterSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user = ser.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {"access": str(refresh.access_token), "refresh": str(refresh)}
        )


class ProviderProfileView(APIView):
    permission_classes = [IsAuthenticated, IsVendor]

    def get(self, request):
        ser = ProfileSerializer(request.user)
        return Response(ser.data)

    def put(self, request):
        ser = ProfileSerializer(request.user, data=request.data)
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(ser.data)


class OrganizationMemberViewSet(viewsets.ViewSet):
    """Manage members within an organization."""

    def get_permissions(self):
        if self.action in ("create", "destroy"):
            perms = [IsAuthenticated, IsOrgOwner]
        else:
            perms = [IsAuthenticated]
        return [p() if isinstance(p, type) else p for p in perms]

    @extend_schema(request=None, responses={201: None})
    def create(self, request, org_id=None):
        org = get_object_or_404(Organization, pk=org_id)
        self.check_object_permissions(request, org)
        user_id = request.data.get("user_id")
        email = request.data.get("email")
        role = request.data.get("role")
        if role not in ("owner", "staff"):
            return Response({"detail": "invalid role"}, status=400)
        if not user_id and not email:
            return Response({"detail": "user_id or email required"}, status=400)
        user = None
        if user_id:
            user = get_object_or_404(User, pk=user_id)
        else:
            user = get_object_or_404(User, email=email)
        if OrganizationMember.objects.filter(organization=org, user=user).exists():
            return Response({"detail": "member exists"}, status=400)
        member = OrganizationMember.objects.create(
            organization=org, user=user, role=role
        )
        return Response({"id": member.id}, status=status.HTTP_201_CREATED)

    @extend_schema(request=None, responses={204: None})
    def destroy(self, request, org_id=None, pk=None):
        org = get_object_or_404(Organization, pk=org_id)
        self.check_object_permissions(request, org)
        try:
            member = OrganizationMember.objects.get(pk=pk, organization=org)
        except OrganizationMember.DoesNotExist:
            return Response({"detail": "no such member"}, status=400)
        member.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MyOrganizationsView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(responses=None)
    def get(self, request):
        memberships = OrganizationMember.objects.filter(
            user=request.user
        ).select_related("organization")
        data = [
            {
                "id": m.organization_id,
                "name": m.organization.name,
                "slug": m.organization.slug,
                "role": m.role,
            }
            for m in memberships
        ]
        return Response(data)
