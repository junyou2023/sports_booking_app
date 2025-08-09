from django.db import migrations, models
import django.db.models.deletion


def forwards(apps, schema_editor):
    Activity = apps.get_model("sports", "Activity")
    User = apps.get_model("auth", "User")
    Organization = apps.get_model("accounts", "Organization")
    OrganizationMember = apps.get_model("accounts", "OrganizationMember")
    import shortuuid

    users = User.objects.filter(activities__isnull=False).distinct()
    for user in users:
        org = Organization.objects.create(
            name=user.username,
            slug=f"{user.username}-{shortuuid.uuid()[:8]}",
        )
        OrganizationMember.objects.create(
            organization=org, user=user, role="owner"
        )
        Activity.objects.filter(owner=user).update(organization=org)


def backwards(apps, schema_editor):
    Activity = apps.get_model("sports", "Activity")
    Organization = apps.get_model("accounts", "Organization")
    OrganizationMember = apps.get_model("accounts", "OrganizationMember")
    for act in Activity.objects.all():
        member = OrganizationMember.objects.filter(
            organization=act.organization, role="owner"
        ).first()
        act.owner = member.user if member else None
        act.save()
    OrganizationMember.objects.all().delete()
    Organization.objects.all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0003_organization"),
        ("sports", "0017_trigram_indexes"),
    ]

    operations = [
        migrations.AddField(
            model_name="activity",
            name="organization",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="activities",
                to="accounts.organization",
            ),
        ),
        migrations.RunPython(forwards, backwards),
        migrations.RemoveField(model_name="activity", name="owner"),
        migrations.AlterField(
            model_name="activity",
            name="organization",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="activities",
                to="accounts.organization",
            ),
        ),
    ]

