from django.contrib import admin
from .models import Profile, ClothingItem, Wardrobe, ClothingOption, Outfit

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("username", "email", "firebase_uid", "plan", "is_admin")
    list_editable = ("is_admin",)
    search_fields = ("username", "email", "firebase_uid")

@admin.register(ClothingItem)
class ClothingItemAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "category", "created_at")
    list_filter = ("category", "season", "occasion")
    search_fields = ("name", "owner__username")

@admin.register(Wardrobe)
class WardrobeAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "is_default", "created_at")
    list_filter = ("is_default",)
    search_fields = ("name", "owner__username")

@admin.register(ClothingOption)
class ClothingOptionAdmin(admin.ModelAdmin):
    list_display = ("type", "name")
    list_filter = ("type",)
    search_fields = ("name",)

@admin.register(Outfit)
class OutfitAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "occasion", "created_at")
    list_filter = ("occasion",)
    search_fields = ("name", "owner__username")
