from django.db import migrations, models


def set_pending(apps, schema_editor):
    Booking = apps.get_model('sports', 'Booking')
    Booking.objects.filter(status__isnull=True).update(status='pending')


class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0019_pricerule_booking_price_slot_is_active_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='booking',
            name='status',
            field=models.CharField(
                max_length=20,
                choices=[
                    ('pending', 'pending'),
                    ('confirmed', 'confirmed'),
                    ('cancelled', 'cancelled'),
                    ('refunded', 'refunded'),
                    ('completed', 'completed'),
                ],
                default='pending',
            ),
        ),
        migrations.RunPython(set_pending, migrations.RunPython.noop),
    ]
