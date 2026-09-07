from django.apps import AppConfig

class GarageAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'garage_app'

    def ready(self):
        import garage_app.signals
