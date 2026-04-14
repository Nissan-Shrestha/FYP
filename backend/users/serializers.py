from rest_framework import serializers
from django.db import models
from .models import ClothingItem, Profile, Wardrobe, ClothingOption, Outfit, Report, Schedule, FeaturedWardrobeRequest

class ClothingOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClothingOption
        fields = '__all__'


class ProfileSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()
    is_featured = serializers.SerializerMethodField()

    can_use_stylist = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            "id", "firebase_uid", "username", "email", "is_admin", "is_superadmin", "plan", "is_premium", "premium_until",
            "wardrobe_count", "wardrobe_limit", "outfits_count", "outfits_limit", 
            "profile_picture", "bio", "social_links", "is_featured", 
            "can_use_stylist", "stylist_available_in", "can_use_analysis", "analysis_available_in", "created_at",
            "fcm_token"
        ]

    def get_stylist_available_in(self, obj):
        return obj.stylist_available_in

    def get_can_use_stylist(self, obj):
        return obj.can_use_stylist

    def get_analysis_available_in(self, obj):
        return obj.analysis_available_in

    def get_can_use_analysis(self, obj):
        return obj.can_use_analysis

    def get_is_featured(self, obj):
        # The badge is shown if the user is featured by Admin, regardless of plan.
        return obj.is_featured

    def get_profile_picture(self, obj):
        if not obj.profile_picture:
            return None
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.profile_picture.url)
        return obj.profile_picture.url


from django.utils import timezone

class ClothingItemSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()
    wear_count = serializers.SerializerMethodField()
    is_locked = serializers.SerializerMethodField()

    class Meta:
        model = ClothingItem
        fields = [
            "id", "owner", "name", "category", "item_type", "color",
            "material", "size", "season", "occasion", "brand",
            "purchase_price", "layer_level", "image", "wear_count", "is_locked", "created_at"
        ]
        read_only_fields = ("id", "owner", "created_at")

    def get_image(self, obj):
        if not obj.image:
            return None
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.image.url)
        return obj.image.url

    def get_wear_count(self, obj):
        # Only count schedules that have actually passed (precisely by the minute)
        return Schedule.objects.filter(
            outfit__items=obj,
            date_time__lte=timezone.now()
        ).count()

    def get_is_locked(self, obj):
        # Check if any associated wardrobe is locked
        from datetime import timedelta
        three_days_ago = timezone.now() - timedelta(days=1)
        return FeaturedWardrobeRequest.objects.filter(
            wardrobe__items=obj
        ).filter(
            models.Q(status='pending', is_paid=True) | 
            models.Q(status='approved', updated_at__gte=three_days_ago)
        ).exists()


class WardrobeSerializer(serializers.ModelSerializer):
    item_count = serializers.SerializerMethodField()
    thumbnail = serializers.SerializerMethodField()
    is_locked = serializers.SerializerMethodField()

    class Meta:
        model = Wardrobe
        fields = ["id", "owner", "name", "is_default", "item_count", "thumbnail", "is_locked", "created_at", "updated_at"]
        read_only_fields = ("id", "owner", "items", "created_at", "updated_at")

    def get_is_locked(self, obj):
        from datetime import timedelta
        three_days_ago = timezone.now() - timedelta(days=1)
        return FeaturedWardrobeRequest.objects.filter(
            wardrobe=obj
        ).filter(
            models.Q(status='pending', is_paid=True) | 
            models.Q(status='approved', updated_at__gte=three_days_ago)
        ).exists()

    def get_item_count(self, obj):
        return obj.items.count()

    def get_thumbnail(self, obj):
        first_item = obj.items.first()
        if not first_item or not first_item.image:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(first_item.image.url)
        return first_item.image.url


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
    owner_social_links = serializers.JSONField(source="owner.social_links", read_only=True)
    owner_bio = serializers.CharField(source="owner.bio", read_only=True)
    owner_is_featured = serializers.SerializerMethodField()
    saves_count = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    def get_owner_is_featured(self, obj):
        # Sync the badge logic for outfits too
        return obj.owner.is_featured

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


class FeaturedWardrobeRequestSerializer(serializers.ModelSerializer):
    wardrobe_name = serializers.CharField(source="wardrobe.name", read_only=True)
    requester_username = serializers.CharField(source="requester.username", read_only=True)
    requester_firebase_uid = serializers.CharField(source="requester.firebase_uid", read_only=True)
    
    class Meta:
        model = FeaturedWardrobeRequest
        fields = "__all__"
        read_only_fields = ("id", "requester", "status", "admin_feedback", "created_at", "updated_at")
