from django.db import migrations, models
import django.core.validators
from decimal import Decimal

class Migration(migrations.Migration):
    dependencies = [
        ("sports", "0022_alter_slot_price"),
    ]

    operations = [
        migrations.AddField(
            model_name="booking",
            name="price",
            field=models.DecimalField(
                max_digits=8,
                decimal_places=2,
                default=Decimal("0.00"),
                validators=[django.core.validators.MinValueValidator(Decimal("0"))],
            ),
        ),
    ]
