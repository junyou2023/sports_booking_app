from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0010_review_model'),
    ]

    operations = [
        migrations.AddField(
            model_name='slot',
            name='activity',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='slots', to='sports.activity'),
        ),
        migrations.AddField(
            model_name='slot',
            name='current_participants',
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name='booking',
            name='activity',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='bookings', to='sports.activity'),
        ),
        migrations.AddField(
            model_name='booking',
            name='status',
            field=models.CharField(default='confirmed', max_length=20),
        ),
        migrations.AddField(
            model_name='booking',
            name='paid',
            field=models.BooleanField(default=False),
        ),
    ]
