import decimal
import random
from uuid import uuid4
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.contrib.gis.geos import Point
from accounts.models import VendorProfile, Organization, OrganizationMember
from sports.models import Facility, Activity, Slot, Sport, Category

User = get_user_model()

def user_factory(**kw):
    idx = random.randint(1000, 9999)
    email = kw.pop("email", f"user{idx}@example.com")
    password = kw.pop("password", "pass1234")
    return User.objects.create_user(username=email, email=email, password=password, **kw)

def vendor_factory(**kw):
    user = user_factory(**kw)
    # ``VendorProfile`` is created automatically via signals when the user is
    # created.  Creating it again would violate the one-to-one constraint and
    # cause many tests to fail with ``IntegrityError``.  Simply ensure the
    # profile exists by touching ``user.vendorprofile``.
    user.vendorprofile  # noqa: B018 - accessed for side effect

    org = Organization.objects.create(
        name=f"Org-{uuid4().hex[:6]}", slug=f"org-{uuid4().hex[:6]}"
    )
    OrganizationMember.objects.create(organization=org, user=user, role="owner")

    class V:
        pass

    v = V()
    v.user = user
    v.org = org
    return v

def facility_factory(lat=0.0, lon=0.0, **kw):
    name = kw.pop("name", f"F-{uuid4().hex[:6]}")
    location = Point(lon, lat)
    return Facility.objects.create(name=name, location=location, radius=kw.pop("radius", 1000))

def activity_factory(**kw):
    sport = kw.pop("sport", Sport.objects.create(name=f"S-{uuid4().hex[:6]}"))
    category = kw.pop("discipline", Category.objects.create(name=f"C-{uuid4().hex[:6]}"))
    org = kw.pop("organization", Organization.objects.create(name=f"O-{uuid4().hex[:6]}", slug=f"org-{uuid4().hex[:6]}"))
    return Activity.objects.create(
        sport=sport,
        discipline=category,
        title=kw.pop("title", "Activity"),
        description=kw.pop("description", ""),
        difficulty=kw.pop("difficulty", 1),
        duration=kw.pop("duration", 60),
        base_price=kw.pop("base_price", decimal.Decimal("10.00")),
        organization=org,
    )

def slot_factory(**kw):
    activity = kw.pop("activity", activity_factory())
    begins = kw.pop("begins_at", timezone.now() + timezone.timedelta(hours=1))
    ends = kw.pop("ends_at", begins + timezone.timedelta(hours=1))
    price = kw.pop("price", decimal.Decimal("9.99"))
    capacity = kw.pop("capacity", 4)
    return Slot.objects.create(
        activity=activity,
        sport=activity.sport,
        title=kw.pop("title", "Slot"),
        location=kw.pop("location", "Loc"),
        begins_at=begins,
        ends_at=ends,
        capacity=capacity,
        price=price,
        facility=kw.pop("facility", None),
    )
