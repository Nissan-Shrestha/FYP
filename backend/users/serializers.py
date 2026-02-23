from rest_framework import serializers
from .models import ClothingItem, Profile, Wardrobe

class ProfileSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = '__all__'

    def get_profile_picture(self, obj):
        return obj.profile_picture.url if obj.profile_picture else None


class ClothingItemSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = ClothingItem
        fields = "__all__"
        read_only_fields = ("id", "owner", "created_at")

    def get_image(self, obj):
        return obj.image.url if obj.image else None


class WardrobeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wardrobe
        fields = "__all__"
        read_only_fields = ("id", "owner", "items", "created_at", "updated_at")
