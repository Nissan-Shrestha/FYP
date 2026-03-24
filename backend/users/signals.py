from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import Wardrobe, ClothingItem, Profile

@receiver(post_save, sender=Wardrobe)
@receiver(post_delete, sender=Wardrobe)
def update_wardrobe_count(sender, instance, **kwargs):
    profile = instance.owner
    profile.wardrobe_count = profile.wardrobes.count()
    profile.save(update_fields=["wardrobe_count"])

@receiver(post_save, sender=ClothingItem)
@receiver(post_delete, sender=ClothingItem)
def update_clothing_info(sender, instance, **kwargs):
    # Depending on what 'outfits_count' refers to. 
    # If there are Outfit models (not seen yet), update them here.
    pass
