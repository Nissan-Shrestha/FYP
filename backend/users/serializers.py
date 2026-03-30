from rest_framework import serializers
from .models import ClothingItem, Profile, Wardrobe, ClothingOption, Outfit, Report, Schedule

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


class OutfitSerializer(serializers.ModelSerializer):
    items = ClothingItemSerializer(many=True, read_only=True)
    item_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
    )
    owner_username = serializers.CharField(source="owner.username", read_only=True)
    owner_firebase_uid = serializers.CharField(source="owner.firebase_uid", read_only=True)
    owner_profile_picture = serializers.ImageField(source="owner.profile_picture", read_only=True)
    saves_count = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    def get_saves_count(self, obj):
        return obj.saved_by.count()

    def get_is_saved(self, obj):
        request = self.context.get("request")
        if request and hasattr(request, "user_profile"):
            return obj.saved_by.filter(id=request.user_profile.id).exists()
        return False

    class Meta:
        model = Outfit
        fields = "__all__"
        read_only_fields = ("id", "owner", "created_at", "updated_at")


class ReportSerializer(serializers.ModelSerializer):
    reporter_username = serializers.CharField(source="reporter.username", read_only=True)
    outfit_name = serializers.CharField(source="outfit.name", read_only=True)
    outfit_owner_username = serializers.CharField(source="outfit.owner.username", read_only=True)
    outfit_owner_firebase_uid = serializers.CharField(source="outfit.owner.firebase_uid", read_only=True)
    outfit_details = OutfitSerializer(source="outfit", read_only=True)

    class Meta:
        model = Report
        fields = "__all__"
        read_only_fields = ("id", "reporter", "created_at", "updated_at")


class ScheduleSerializer(serializers.ModelSerializer):
    outfit_details = OutfitSerializer(source="outfit", read_only=True)
    
    class Meta:
        model = Schedule
        fields = "__all__"
        read_only_fields = ("id", "owner", "created_at", "updated_at")
