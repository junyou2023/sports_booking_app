from django.apps import AppConfig


class SportsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'

    name = 'sports'

    def ready(self):
        from . import signals  # noqa: F401
