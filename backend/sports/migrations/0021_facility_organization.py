from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0004_organizationmember_is_default"),
        ("sports", "0020_booking_status_choices"),
    ]

    operations = [
        migrations.AddField(
            model_name="facility",
            name="organization",
            field=models.ForeignKey(
                to="accounts.organization",
                on_delete=models.CASCADE,
                related_name="facilities",
                null=True,
                blank=True,
            ),
        ),
    ]
