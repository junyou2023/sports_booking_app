from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0003_organization"),
    ]

    operations = [
        migrations.AddField(
            model_name="organizationmember",
            name="is_default",
            field=models.BooleanField(default=False),
        ),
    ]
