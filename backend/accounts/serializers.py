from django.contrib.auth.models import User
from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
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
        source="customerprofile.phone", required=False
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
        customer = getattr(instance, "customerprofile", None)
        return {
            "email": instance.email,
            "is_provider": hasattr(instance, "vendorprofile"),
            "company_name": getattr(vendor, "company_name", ""),
            "phone": getattr(customer, "phone", ""),
            "address": getattr(vendor, "address", ""),
            "logo": getattr(vendor, "logo", ""),
        }

    def update(self, instance: User, validated_data):
        vendor_data = validated_data.get("vendorprofile", {})
        vendor, _ = VendorProfile.objects.get_or_create(user=instance)
        customer, _ = CustomerProfile.objects.get_or_create(user=instance)
        vendor.company_name = vendor_data.get(
            "company_name", vendor.company_name
        )
        customer.phone = vendor_data.get("phone", customer.phone)
        vendor.address = vendor_data.get("address", vendor.address)
        vendor.logo = vendor_data.get("logo", vendor.logo)
        vendor.save()
        customer.save()
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
        vendor, _ = VendorProfile.objects.get_or_create(user=user)
        vendor.company_name = company
        vendor.phone = phone
        vendor.address = address
        vendor.save()
        from .models import Organization, OrganizationMember
        import shortuuid

        org = Organization.objects.create(
            name=company or user.username,
            slug=f"{user.username}-{shortuuid.uuid()[:8]}",
        )
        OrganizationMember.objects.create(
            organization=org, user=user, role="owner"
        )
        return user


class EmailOrUsernameTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Allow authentication via either email or username."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # allow username to be optional when email is provided
        self.fields[self.username_field].required = False
        self.fields['email'] = serializers.EmailField(required=False)

    def validate(self, attrs):
        if attrs.get('email') and not attrs.get(self.username_field):
            User = get_user_model()
            try:
                user = User.objects.get(email=attrs['email'])
                attrs[self.username_field] = getattr(
                    user, User.USERNAME_FIELD, user.username
                )
            except User.DoesNotExist:
                # fall back to allow default 401 behavior
                attrs[self.username_field] = attrs['email']
        return super().validate(attrs)
