from django.utils.text import slugify
from accounts.models import Organization, OrganizationMember


def get_or_create_single_org_for_user(user):
    """Return the provider's single organization, creating if needed.

    Picks an existing owner organization if available, otherwise the earliest
    membership. If none exist, creates a new organization and assigns the user
    as owner.
    """
    assert hasattr(user, "vendorprofile"), "user must be a provider (has VendorProfile)."

    owner_member = (
        OrganizationMember.objects.filter(user=user, role="owner")
        .select_related("organization")
        .order_by("organization__created_at", "organization__id")
        .first()
    )
    if owner_member:
        org = owner_member.organization
    else:
        member = (
            OrganizationMember.objects.filter(user=user)
            .select_related("organization")
            .order_by("organization__created_at", "organization__id")
            .first()
        )
        if member:
            org = member.organization
        else:
            name = f"{user.username or 'provider'}-{user.id}"
            org = Organization.objects.create(name=name, slug=slugify(name))
            OrganizationMember.objects.get_or_create(
                organization=org, user=user, defaults={"role": "owner"}
            )
    OrganizationMember.objects.get_or_create(
        organization=org, user=user, defaults={"role": "owner"}
    )
    return org
