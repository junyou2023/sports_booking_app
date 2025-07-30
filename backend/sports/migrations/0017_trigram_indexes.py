from django.conf import settings
from django.db import migrations


def forwards(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor != 'postgresql':
        return
    if not getattr(settings, 'USE_TRIGRAM', False):
        return
    schema_editor.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;")
    schema_editor.execute(
        "CREATE INDEX IF NOT EXISTS sports_activity_title_trgm ON sports_activity USING gin (title gin_trgm_ops);"
    )
    schema_editor.execute(
        "CREATE INDEX IF NOT EXISTS sports_activity_description_trgm ON sports_activity USING gin (description gin_trgm_ops);"
    )
    schema_editor.execute(
        "CREATE INDEX IF NOT EXISTS sports_facility_name_trgm ON sports_facility USING gin (name gin_trgm_ops);"
    )


def backwards(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor != 'postgresql':
        return
    if not getattr(settings, 'USE_TRIGRAM', False):
        return
    schema_editor.execute("DROP INDEX IF EXISTS sports_activity_title_trgm;")
    schema_editor.execute("DROP INDEX IF EXISTS sports_activity_description_trgm;")
    schema_editor.execute("DROP INDEX IF EXISTS sports_facility_name_trgm;")


class Migration(migrations.Migration):
    dependencies = [
        ('sports', '0016_favorite_model'),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
    ]
