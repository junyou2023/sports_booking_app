from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("sports", "0015_add_payment_intent_id"),
    ]

    operations = [
        migrations.RenameField(
            model_name="featuredcategory",
            old_name="order",
            new_name="display_order",
        ),
        migrations.AddField(
            model_name="featuredcategory",
            name="show_on_home",
            field=models.BooleanField(default=True),
        ),
        migrations.AlterModelOptions(
            name="featuredcategory",
            options={"ordering": ("display_order",)},
        ),
    ]
