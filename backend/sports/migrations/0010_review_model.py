from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0009_image_fields_and_is_nearby'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Review',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rating', models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])),
                ('comment', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('activity', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reviews', to='sports.activity')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ('-created_at',),
            },
        ),
    ]
