from django.contrib.auth.models import User
from rest_framework import serializers
from .models import VendorProfile


class ProfileSerializer(serializers.Serializer):
    email = serializers.EmailField()
    company_name = serializers.CharField(source="vendorprofile.company_name", required=False)
    phone = serializers.CharField(source="vendorprofile.phone", required=False)
    address = serializers.CharField(source="vendorprofile.address", required=False)
    logo = serializers.URLField(source="vendorprofile.logo", required=False)

    class Meta:
        fields = ["email", "company_name", "phone", "address", "logo"]

    def to_representation(self, instance: User):
        vendor = getattr(instance, "vendorprofile", None)
        return {
            "email": instance.email,
            "company_name": getattr(vendor, "company_name", ""),
            "phone": getattr(vendor, "phone", ""),
            "address": getattr(vendor, "address", ""),
            "logo": getattr(vendor, "logo", ""),
        }

    def update(self, instance: User, validated_data):
        vendor_data = validated_data.get("vendorprofile", {})
        vendor, _ = VendorProfile.objects.get_or_create(user=instance)
        vendor.company_name = vendor_data.get("company_name", vendor.company_name)
        vendor.phone = vendor_data.get("phone", vendor.phone)
        vendor.address = vendor_data.get("address", vendor.address)
        vendor.logo = vendor_data.get("logo", vendor.logo)
        vendor.save()
        return instance
