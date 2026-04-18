from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import Wardrobe, ClothingItem, Profile, Outfit, FeaturedWardrobeRequest, Report

@receiver(post_save, sender=Wardrobe)
@receiver(post_delete, sender=Wardrobe)
def update_wardrobe_count(sender, instance, **kwargs):
    profile = instance.owner
    profile.wardrobe_count = profile.wardrobes.count()
    profile.save(update_fields=["wardrobe_count"])

@receiver(post_save, sender=Outfit)
@receiver(post_delete, sender=Outfit)
def update_outfit_count(sender, instance, **kwargs):
    profile = instance.owner
    profile.outfits_count = profile.outfits.count()
    profile.save(update_fields=["outfits_count"])

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

@receiver(post_save, sender=ClothingItem)
@receiver(post_delete, sender=ClothingItem)
def update_clothing_info(sender, instance, **kwargs):
    profile = instance.owner
    # If adding a single clothing item affects his count (not wardrobes or outfits)
    # The current Profile model has 'wardrobe_count' but it seems to refer to wardrobes?
    # Actually, lines 12-13 in model suggest 'wardrobe_count' is for items.
    pass
