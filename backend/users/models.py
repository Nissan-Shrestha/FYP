from django.db import models

class Profile(models.Model):
    firebase_uid = models.CharField(max_length=255, unique=True)
    username = models.CharField(max_length=150)
    email = models.EmailField()

    plan = models.CharField(max_length=50, default="Free")
    wardrobe_count = models.IntegerField(default=0)
    wardrobe_limit = models.IntegerField(default=100)

    outfits_count = models.IntegerField(default=0)
    outfits_limit = models.IntegerField(default=200)

    
    currency = models.CharField(max_length=10, default="USD")

    profile_picture = models.ImageField(upload_to="profile_pics/", null=True, blank=True)

    def __str__(self):
        return self.username
