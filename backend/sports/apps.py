from django.apps import AppConfig


class SportsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    # The app lives under the backend package so Django must know the full
    # Python path. Without this, management commands can't locate models
    # correctly and will raise "Model class ... doesn't declare an explicit
    # app_label" errors.
    name = 'backend.sports'
