from django.db.models.signals import post_save, post_delete
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


