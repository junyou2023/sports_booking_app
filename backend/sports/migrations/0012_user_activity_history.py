from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone
from django.conf import settings


class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0011_booking_slot_updates'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='UserActivityHistory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('action', models.CharField(choices=[('view', 'View'), ('favorite', 'Favorite'), ('book', 'Book')], max_length=10)),
                ('timestamp', models.DateTimeField(default=django.utils.timezone.now)),
                ('activity', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='user_history', to='sports.activity')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activity_history', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ('-timestamp',)},
        ),
    ]
