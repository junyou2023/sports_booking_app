from django.db import migrations

def forwards(apps, schema_editor):
    Slot = apps.get_model('sports', 'Slot')
    for slot in Slot.objects.filter(sport__isnull=True, activity__isnull=False):
        slot.sport_id = slot.activity.sport_id
        slot.save(update_fields=['sport'])


def backwards(apps, schema_editor):
    # No-op
    pass


class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0013_slot_activity_required'),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
    ]
