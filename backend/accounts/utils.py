from uuid import uuid4
from django.db import transaction
from django.utils.text import slugify
from .models import Organization, OrganizationMember


def get_or_create_primary_org(user):
    """Return user's default organization, creating one if needed."""
    member = (
        OrganizationMember.objects.filter(user=user, is_default=True)
        .select_related("organization")
        .first()
    )
    if member:
        return member.organization

    memberships = list(
        OrganizationMember.objects.filter(user=user).select_related("organization")[:2]
    )
    if len(memberships) == 1:
        return memberships[0].organization

    if not memberships:
        with transaction.atomic():
            name = f"{user.get_full_name() or user.username}'s Org"
            base_slug = slugify(name) or f"org-{uuid4().hex[:8]}"
            slug = base_slug
            while Organization.objects.filter(slug=slug).exists():
                slug = f"{base_slug}-{uuid4().hex[:8]}"
            org = Organization.objects.create(name=name, slug=slug)
            OrganizationMember.objects.create(
                organization=org,
                user=user,
                role=OrganizationMember.ROLE_OWNER,
                is_default=True,
            )
        return org

    # multiple memberships but none default - mark the first as default
    member = memberships[0]
    member.is_default = True
    member.save(update_fields=["is_default"])
    return member.organization
