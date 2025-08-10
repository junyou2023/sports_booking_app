from rest_framework import viewsets, permissions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response

from accounts.permissions import IsOrgMember
from .models import Slot, PriceRule
from .serializers import (
    SlotSerializer,
    SlotCreateSerializer,
    SlotUpdateSerializer,
    PriceRuleSerializer,
)


class MerchantSlotViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated, IsOrgMember]

    def get_queryset(self):
        user = self.request.user
        return Slot.objects.filter(
            activity__organization__members__user=user,
            is_active=True,
        ).select_related("activity")

    def get_serializer_class(self):
        if self.action == "create":
            return SlotCreateSerializer
        if self.action in ("update", "partial_update"):
            return SlotUpdateSerializer
        return SlotSerializer

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active"])


class MerchantSlotBulkDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        ids = request.data.get("ids", [])
        if not isinstance(ids, list):
            raise serializers.ValidationError({"ids": "Must be a list"})
        ids = list({int(i) for i in ids}) if ids else []

        existing = Slot.objects.filter(id__in=ids, is_active=True)
        existing_ids = set(existing.values_list("id", flat=True))
        allowed = existing.filter(activity__organization__members__user=request.user)
        allowed_ids = set(allowed.values_list("id", flat=True))
        deleted = allowed.update(is_active=False)
        not_found = [i for i in ids if i not in existing_ids]
        forbidden = [i for i in ids if i in existing_ids and i not in allowed_ids]
        return Response({
            "deleted": deleted,
            "forbidden": forbidden,
            "not_found": not_found,
        })


class PriceRuleViewSet(viewsets.ModelViewSet):
    serializer_class = PriceRuleSerializer
    permission_classes = [permissions.IsAuthenticated, IsOrgMember]

    def get_queryset(self):
        return PriceRule.objects.filter(
            activity__organization__members__user=self.request.user
        )

    def perform_create(self, serializer):
        activity = serializer.validated_data["activity"]
        if not activity.organization.members.filter(user=self.request.user).exists():
            raise permissions.PermissionDenied("Not a member of this organization")
        serializer.save()
