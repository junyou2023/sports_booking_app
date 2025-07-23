from django.db import migrations, models
import csv

def forwards(apps, schema_editor):
    Slot = apps.get_model('sports', 'Slot')
    Activity = apps.get_model('sports', 'Activity')
    orphans = []
    for slot in Slot.objects.filter(activity__isnull=True):
        act = Activity.objects.filter(sport=slot.sport).first()
        if act:
            slot.activity_id = act.id
            slot.save(update_fields=['activity'])
        else:
            orphans.append(slot.id)
    if orphans:
        path = schema_editor.connection.alias if hasattr(schema_editor, 'connection') else 'default'
        with open('orphan_slots.csv', 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['slot_id'])
            for sid in orphans:
                writer.writerow([sid])

def backwards(apps, schema_editor):
    # no-op
    pass

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0012_user_activity_history'),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
        migrations.AlterField(
            model_name='slot',
            name='activity',
            field=models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='slots', to='sports.activity'),
        ),
        migrations.AlterUniqueTogether(
            name='slot',
            unique_together={('activity', 'begins_at')},
        ),
    ]

