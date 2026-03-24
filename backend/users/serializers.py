from rest_framework import serializers
from .models import ClothingItem, Profile, Wardrobe, ClothingOption

class ClothingOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClothingOption
        fields = '__all__'


class ProfileSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = '__all__'

    def get_profile_picture(self, obj):
        if not obj.profile_picture:
            return None
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.profile_picture.url)
        return obj.profile_picture.url


class ClothingItemSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = ClothingItem
        fields = "__all__"
        read_only_fields = ("id", "owner", "created_at")

    def get_image(self, obj):
        if not obj.image:
            return None
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.image.url)
        return obj.image.url


class WardrobeSerializer(serializers.ModelSerializer):
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = Wardrobe
        fields = "__all__"
        read_only_fields = ("id", "owner", "items", "created_at", "updated_at")

    def get_item_count(self, obj):
        return obj.items.count()
