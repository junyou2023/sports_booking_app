from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0010_review_model'),
    ]

    operations = [
        migrations.AddField(
            model_name='activity',
            name='status',
            field=models.CharField(choices=[('draft', 'Draft'), ('published', 'Published')], default='draft', max_length=10),
        ),
    ]
