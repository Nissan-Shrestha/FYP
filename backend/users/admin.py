from django.contrib import admin
from .models import Profile, ClothingItem, Wardrobe

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
