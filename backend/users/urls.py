from django.urls import path
from .views import get_or_create_profile

urlpatterns = [
    path("profile/", get_or_create_profile),
]
