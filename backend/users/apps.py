from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'users'

    def ready(self):
        from .firebase_auth import initialize_firebase
        from . import signals  # Register signals
        initialize_firebase()
