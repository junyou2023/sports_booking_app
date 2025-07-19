from django.contrib.auth.models import User
from rest_framework import serializers
from .models import VendorProfile


class ProfileSerializer(serializers.Serializer):
    email = serializers.EmailField()
    is_provider = serializers.BooleanField(
        source="is_provider", read_only=True
    )
    company_name = serializers.CharField(
        source="vendorprofile.company_name", required=False
    )
    phone = serializers.CharField(
        source="vendorprofile.phone", required=False
    )
    address = serializers.CharField(
        source="vendorprofile.address", required=False
    )
    logo = serializers.URLField(
        source="vendorprofile.logo", required=False
    )

    class Meta:
        fields = [
            "email",
            "is_provider",
            "company_name",
            "phone",
            "address",
            "logo",
        ]

    def to_representation(self, instance: User):
        vendor = getattr(instance, "vendorprofile", None)
        return {
            "email": instance.email,
            "is_provider": hasattr(instance, "vendorprofile"),
            "company_name": getattr(vendor, "company_name", ""),
            "phone": getattr(vendor, "phone", ""),
            "address": getattr(vendor, "address", ""),
            "logo": getattr(vendor, "logo", ""),
        }

    def update(self, instance: User, validated_data):
        vendor_data = validated_data.get("vendorprofile", {})
        vendor, _ = VendorProfile.objects.get_or_create(user=instance)
        vendor.company_name = vendor_data.get(
            "company_name", vendor.company_name
        )
        vendor.phone = vendor_data.get("phone", vendor.phone)
        vendor.address = vendor_data.get("address", vendor.address)
        vendor.logo = vendor_data.get("logo", vendor.logo)
        vendor.save()
        return instance


class ProviderRegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password1 = serializers.CharField(write_only=True)
    password2 = serializers.CharField(write_only=True)
    company_name = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        if attrs.get("password1") != attrs.get("password2"):
            raise serializers.ValidationError("Passwords do not match")
        return attrs

    def create(self, validated_data):
        validated_data.pop("password2")
        company = validated_data.pop("company_name", "")
        phone = validated_data.pop("phone", "")
        address = validated_data.pop("address", "")
        user = User.objects.create_user(
            username=validated_data["email"],
            email=validated_data["email"],
            password=validated_data["password1"],
        )
        VendorProfile.objects.create(
            user=user,
            company_name=company,
            phone=phone,
            address=address,
        )
        return user
