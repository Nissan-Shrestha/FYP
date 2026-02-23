from rest_framework import serializers
from .models import ClothingItem, Profile, Wardrobe

class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = '__all__'


class ClothingItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClothingItem
        fields = "__all__"
        read_only_fields = ("id", "owner", "created_at")


class WardrobeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wardrobe
        fields = "__all__"
        read_only_fields = ("id", "owner", "items", "created_at", "updated_at")
