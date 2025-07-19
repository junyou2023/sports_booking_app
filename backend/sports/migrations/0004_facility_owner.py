from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0003_variant_activity'),
    ]

    operations = [
        migrations.AddField(
            model_name='facility',
            name='owner',
            field=models.ForeignKey(null=True, blank=True, on_delete=django.db.models.deletion.CASCADE, related_name='facilities', to=settings.AUTH_USER_MODEL),
        ),
    ]
