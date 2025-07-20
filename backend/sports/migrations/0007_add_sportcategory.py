from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0006_activity_image'),
    ]

    operations = [
        migrations.CreateModel(
            name='SportCategory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=60)),
                ('parent', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='children', to='sports.sportcategory')),
            ],
            options={'ordering': ('name',)},
        ),
        migrations.AddConstraint(
            model_name='sportcategory',
            constraint=models.UniqueConstraint(fields=('parent', 'name'), name='uniq_cat_parent_name'),
        ),
    ]
