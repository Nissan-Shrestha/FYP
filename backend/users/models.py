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


class ClothingItem(models.Model):
    owner = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name="clothing_items",
    )
    name = models.CharField(max_length=150)
    category = models.CharField(max_length=100, blank=True)
    season = models.CharField(max_length=50, blank=True)
    occasion = models.CharField(max_length=100, blank=True)
    size = models.CharField(max_length=50, blank=True)
    material = models.CharField(max_length=100, blank=True)
    brand = models.CharField(max_length=100, blank=True)
    image = models.ImageField(upload_to="clothing_items/", null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.owner.username})"


class Wardrobe(models.Model):
    owner = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name="wardrobes",
    )
    name = models.CharField(max_length=150)
    is_default = models.BooleanField(default=False)
    items = models.ManyToManyField(
        ClothingItem,
        related_name="wardrobes",
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "name"],
                name="unique_wardrobe_name_per_user",
            ),
        ]

    def __str__(self):
        return f"{self.name} ({self.owner.username})"
