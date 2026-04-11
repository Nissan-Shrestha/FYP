from django.contrib import admin
from .models import Profile, ClothingItem, Wardrobe, ClothingOption, Outfit, FeaturedWardrobeRequest, Report, Schedule

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("username", "email", "firebase_uid", "plan", "is_admin")
    list_editable = ("is_admin",)
    search_fields = ("username", "email", "firebase_uid")

@admin.register(ClothingItem)
class ClothingItemAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "item_type", "category", "layer_level", "created_at")
    list_filter = ("item_type", "category", "season", "occasion")
    search_fields = ("name", "owner__username")

@admin.register(Wardrobe)
class WardrobeAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "is_default", "created_at")
    list_filter = ("is_default",)
    search_fields = ("name", "owner__username")

@admin.register(ClothingOption)
class ClothingOptionAdmin(admin.ModelAdmin):
    list_display = ("type", "name", "item_type", "layer_level")
    list_filter = ("type", "item_type")
    search_fields = ("name",)

@admin.register(Outfit)
class OutfitAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "occasion", "created_at")
    list_filter = ("occasion",)
    search_fields = ("name", "owner__username")

@admin.register(FeaturedWardrobeRequest)
class FeaturedWardrobeRequestAdmin(admin.ModelAdmin):
    list_display = ("requester", "wardrobe", "status", "is_paid", "created_at")
    list_filter = ("status", "is_paid")
    search_fields = ("requester__username", "wardrobe__name")
    list_editable = ("status",)

@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ("reporter", "outfit", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("reporter__username", "reason")

@admin.register(Schedule)
class ScheduleAdmin(admin.ModelAdmin):
    list_display = ("event_title", "owner", "date_time", "outfit")
    list_filter = ("date_time",)
    search_fields = ("event_title", "owner__username")
