from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0014_fill_slot_sport'),
    ]

    operations = [
        migrations.AddField(
            model_name='booking',
            name='payment_intent_id',
            field=models.CharField(max_length=255, null=True, blank=True),
        ),
    ]
