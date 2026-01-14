from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """
    Custom user model synced with Firebase users.
    """

    firebase_uid = models.CharField(
        max_length=128,
        unique=True,
        null=True,
        blank=True,
    )

    email = models.EmailField(unique=True)

    def __str__(self):
        return self.email
