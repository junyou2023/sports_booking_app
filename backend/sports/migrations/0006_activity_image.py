from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ("sports", "0005_add_activity_owner"),
    ]

    operations = [
        migrations.AddField(
            model_name="activity",
            name="image",
            field=models.URLField(blank=True),
        ),
    ]
