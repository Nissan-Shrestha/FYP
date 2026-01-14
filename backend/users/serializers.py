from rest_framework import serializers
from .models import User

from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['firebase_uid', 'username', 'email']  # no password here
