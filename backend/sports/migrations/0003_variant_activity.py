from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0002_category_alter_slot_sport_facility_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='Variant',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=30)),
                ('discipline', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='variants', to='sports.category')),
            ],
            options={'ordering': ('name',), 'unique_together': {('discipline', 'name')}},
        ),
        migrations.CreateModel(
            name='Activity',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=60)),
                ('description', models.TextField(blank=True, max_length=500)),
                ('difficulty', models.PositiveSmallIntegerField(default=1)),
                ('duration', models.PositiveIntegerField(default=60, help_text='Minutes')),
                ('base_price', models.DecimalField(decimal_places=2, default=0, max_digits=7)),
                ('discipline', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activities', to='sports.category')),
                ('sport', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activities', to='sports.sport')),
                ('variant', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='activities', to='sports.variant')),
            ],
            options={'ordering': ('sport', 'discipline', 'title')},
        ),
    ]

