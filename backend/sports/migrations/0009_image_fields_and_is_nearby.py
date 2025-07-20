from django.db import migrations, models


def copy_image_fields(apps, schema_editor):
    Category = apps.get_model('sports', 'Category')
    Activity = apps.get_model('sports', 'Activity')
    for c in Category.objects.all():
        val = getattr(c, 'image')
        if isinstance(val, str) and val.startswith(('http', 'https')):
            c.image = val
            c.save(update_fields=['image'])
    for a in Activity.objects.all():
        val = getattr(a, 'image')
        if isinstance(val, str) and val.startswith(('http', 'https')):
            a.image = val
            a.save(update_fields=['image'])

class Migration(migrations.Migration):

    dependencies = [
        ('sports', '0008_featured'),
    ]

    operations = [
        migrations.RenameField(
            model_name='category',
            old_name='icon',
            new_name='image',
        ),
        migrations.AlterField(
            model_name='category',
            name='image',
            field=models.ImageField(blank=True, upload_to='category/'),
        ),
        migrations.AlterField(
            model_name='activity',
            name='image',
            field=models.ImageField(blank=True, upload_to='activity/'),
        ),
        migrations.AddField(
            model_name='activity',
            name='is_nearby',
            field=models.BooleanField(default=False),
        ),
        migrations.RunPython(copy_image_fields, migrations.RunPython.noop),
    ]
