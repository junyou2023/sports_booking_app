from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='vendorprofile',
            name='logo',
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name='vendorprofile',
            name='phone',
            field=models.CharField(max_length=20, blank=True),
        ),
        migrations.AddField(
            model_name='vendorprofile',
            name='address',
            field=models.CharField(max_length=200, blank=True),
        ),
    ]
