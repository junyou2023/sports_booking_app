from django.db import migrations, models


def set_pending(apps, schema_editor):
    Booking = apps.get_model('sports', 'Booking')
    Booking.objects.filter(status__isnull=True).update(status='pending')


class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0019_slot_is_active_alter_activity_organization_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='booking',
            name='status',
            field=models.CharField(max_length=20, choices=[
                ('pending', 'Pending'),
                ('confirmed', 'Confirmed'),
                ('cancelled', 'Cancelled'),
                ('refunded', 'Refunded'),
                ('completed', 'Completed'),
            ], default='pending'),
        ),
        migrations.RunPython(set_pending, migrations.RunPython.noop),
    ]
