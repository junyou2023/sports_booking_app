from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('sports', '0007_add_sportcategory'),
    ]

    operations = [
        migrations.AlterField(
            model_name='category',
            name='icon',
            field=models.ImageField(blank=True, upload_to='category_icons/'),
        ),
        migrations.CreateModel(
            name='FeaturedCategory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', models.ImageField(upload_to='home_categories/')),
                ('order', models.PositiveSmallIntegerField(default=0)),
                ('category', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='sports.category')),
            ],
            options={'ordering': ('order',)},
        ),
        migrations.CreateModel(
            name='FeaturedActivity',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', models.ImageField(upload_to='home_activities/')),
                ('order', models.PositiveSmallIntegerField(default=0)),
                ('activity', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='sports.activity')),
            ],
            options={'ordering': ('order',)},
        ),
    ]

