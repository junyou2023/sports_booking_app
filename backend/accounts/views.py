from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from .permissions import IsVendor
from rest_framework.response import Response

from .serializers import ProfileSerializer


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
