from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0020_booking_status_choices'),
    ]

    operations = [
        migrations.AddField(
            model_name='slot',
            name='owner',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='owned_slots',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]
