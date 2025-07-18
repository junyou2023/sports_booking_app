# Generated by Django 5.2.3 on 2025-07-05 14:35

import django.core.validators
import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Sport",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("name", models.CharField(max_length=30, unique=True)),
                ("banner", models.URLField(blank=True)),
                ("description", models.TextField(blank=True)),
            ],
            options={
                "ordering": ("name",),
            },
        ),
        migrations.CreateModel(
            name="Slot",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("title", models.CharField(max_length=60)),
                ("location", models.CharField(max_length=80)),
                ("begins_at", models.DateTimeField()),
                ("ends_at", models.DateTimeField()),
                (
                    "capacity",
                    models.PositiveSmallIntegerField(
                        validators=[django.core.validators.MinValueValidator(1)]
                    ),
                ),
                (
                    "price",
                    models.DecimalField(decimal_places=2, default=0, max_digits=7),
                ),
                (
                    "rating",
                    models.DecimalField(
                        decimal_places=1,
                        default=0,
                        help_text="Average rating 0–5",
                        max_digits=3,
                    ),
                ),
                (
                    "sport",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="slots",
                        to="sports.sport",
                    ),
                ),
            ],
            options={
                "ordering": ("begins_at",),
                "unique_together": {("sport", "begins_at")},
            },
        ),
        migrations.CreateModel(
            name="Booking",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("booked_at", models.DateTimeField(default=django.utils.timezone.now)),
                (
                    "pax",
                    models.PositiveSmallIntegerField(
                        default=1,
                        help_text="Number of people booked",
                        validators=[
                            django.core.validators.MinValueValidator(1),
                            django.core.validators.MaxValueValidator(20),
                        ],
                    ),
                ),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "slot",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="bookings",
                        to="sports.slot",
                    ),
                ),
            ],
            options={
                "ordering": ("-booked_at",),
                "unique_together": {("slot", "user")},
            },
        ),
    ]
