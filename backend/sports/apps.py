from django.apps import AppConfig


class SportsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    # use the full Python path so Django can load the app regardless of
    # the current working directory
    name = 'backend.sports'
