import os
from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from .models import Wardrobe, ClothingItem, Profile, Outfit, FeaturedWardrobeRequest, Report

@receiver(post_delete, sender=Outfit)
def resolve_reports_on_outfit_delete(sender, instance, **kwargs):
    """
    When an outfit is deleted, mark any pending reports as 'resolved' automatically.
    """
    Report.objects.filter(outfit=instance, status='pending').update(status='resolved')

@receiver(post_delete, sender=FeaturedWardrobeRequest)
def resolve_reports_on_featured_delete(sender, instance, **kwargs):
    """
    When a featured request is deleted, mark any pending reports as 'resolved'.
    """
    Report.objects.filter(featured_request=instance, status='pending').update(status='resolved')

# --- AUTO-CLEANUP SIGNALS ---

@receiver(post_delete, sender=ClothingItem)
def auto_delete_file_on_delete_item(sender, instance, **kwargs):
    """Deletes old file from filesystem when ClothingItem is deleted."""
    if instance.image:
        if os.path.isfile(instance.image.path):
            os.remove(instance.image.path)

@receiver(pre_save, sender=ClothingItem)
def auto_delete_file_on_change_item(sender, instance, **kwargs):
    """Deletes old file from filesystem when ClothingItem is updated with new file."""
    if not instance.pk:
        return False

    try:
        old_file = ClothingItem.objects.get(pk=instance.pk).image
    except ClothingItem.DoesNotExist:
        return False

    new_file = instance.image
    if not old_file == new_file:
        if old_file and os.path.isfile(old_file.path):
            os.remove(old_file.path)

@receiver(post_delete, sender=Profile)
def auto_delete_file_on_delete_profile(sender, instance, **kwargs):
    """Deletes old file from filesystem when Profile is deleted."""
    if instance.profile_picture:
        if os.path.isfile(instance.profile_picture.path):
            os.remove(instance.profile_picture.path)

@receiver(pre_save, sender=Profile)
def auto_delete_file_on_change_profile(sender, instance, **kwargs):
    """Deletes old file from filesystem when Profile is updated with new file or removed."""
    if not instance.pk:
        return False

    try:
        old_file = Profile.objects.get(pk=instance.pk).profile_picture
    except Profile.DoesNotExist:
        return False

    new_file = instance.profile_picture
    if not old_file == new_file:
        if old_file and os.path.isfile(old_file.path):
            os.remove(old_file.path)

