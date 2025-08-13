from django.db import migrations, models
import django.core.validators
from decimal import Decimal

class Migration(migrations.Migration):
    dependencies = [
        ("sports", "0021_merge_20250812_2242"),
    ]

    operations = [
        migrations.AlterField(
            model_name="slot",
            name="price",
            field=models.DecimalField(
                max_digits=8,
                decimal_places=2,
                validators=[django.core.validators.MinValueValidator(Decimal("0.50"))],
            ),
        ),
    ]
