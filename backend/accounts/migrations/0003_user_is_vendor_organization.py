from django.db import migrations, models
from django.conf import settings
from django.utils.text import slugify


def create_org_for_existing_vendors(apps, schema_editor):
    User = apps.get_model('auth', 'User')
    Organization = apps.get_model('accounts', 'Organization')
    OrganizationMember = apps.get_model('accounts', 'OrganizationMember')
    for user in User.objects.filter(is_staff=True):
        org = Organization.objects.create(
            name=user.username,
            slug=slugify(f'default-{user.pk}')
        )
        OrganizationMember.objects.create(
            organization=org,
            user=user,
            role='owner'
        )
        user.is_vendor = True
        user.is_staff = False
        user.save(update_fields=['is_vendor', 'is_staff'])


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0002_vendor_extra_fields'),
    ]

    operations = [
        migrations.RunSQL(
            'ALTER TABLE auth_user ADD COLUMN is_vendor BOOLEAN NOT NULL DEFAULT FALSE;'
        ),
        migrations.RunSQL(
            'CREATE INDEX auth_user_is_vendor_idx ON auth_user (is_vendor);',
            'DROP INDEX auth_user_is_vendor_idx;'
        ),
        migrations.CreateModel(
            name='Organization',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=120)),
                ('slug', models.SlugField(unique=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='OrganizationMember',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('role', models.CharField(choices=[('owner', 'Owner'), ('staff', 'Staff')], max_length=10)),
                ('organization', models.ForeignKey(on_delete=models.CASCADE, related_name='members', to='accounts.organization')),
                ('user', models.ForeignKey(on_delete=models.CASCADE, related_name='orgs', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.RunPython(create_org_for_existing_vendors, noop),
    ]
