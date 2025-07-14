from django.contrib.auth.models import User
from rest_framework import serializers


class ProfileSerializer(serializers.Serializer):
    email = serializers.EmailField()
    company_name = serializers.CharField(source="vendorprofile.company_name")
    phone = serializers.CharField(source="customerprofile.phone")

    class Meta:
        fields = ["email", "company_name", "phone"]

    def to_representation(self, instance: User):
        return {
            "email": instance.email,
            "company_name": getattr(
                instance.vendorprofile,
                "company_name",
                "",
            ),
            "phone": getattr(instance.customerprofile, "phone", ""),
        }
