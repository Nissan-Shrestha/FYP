from django.db import models
from django.utils import timezone


class Profile(models.Model):
    firebase_uid = models.CharField(max_length=255, unique=True)
    username = models.CharField(max_length=150)
    email = models.EmailField()
    is_admin = models.BooleanField(default=False)

    plan = models.CharField(max_length=50, default="Free")
    wardrobe_count = models.IntegerField(default=0)
    wardrobe_limit = models.IntegerField(default=100)

    outfits_count = models.IntegerField(default=0)
    outfits_limit = models.IntegerField(default=200)

    currency = models.CharField(max_length=10, default="USD")
    profile_picture = models.ImageField(upload_to="profile_pics/", null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return self.username


class ClothingOption(models.Model):
    OPTION_TYPES = [
        ('category', 'Category'),
        ('season', 'Season'),
        ('occasion', 'Occasion'),
        ('size', 'Size'),
        ('material', 'Material'),
    ]
    type = models.CharField(max_length=20, choices=OPTION_TYPES)
    name = models.CharField(max_length=50)

    class Meta:
        unique_together = ('type', 'name')

    def __str__(self):
        return f"[{self.type}] {self.name}"


class ClothingItem(models.Model):
    owner = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name="clothing_items",
    )
    name = models.CharField(max_length=150)
    category = models.CharField(max_length=100)
    season = models.CharField(max_length=50)
    occasion = models.CharField(max_length=100)
    size = models.CharField(max_length=50)
    material = models.CharField(max_length=100)
    brand = models.CharField(max_length=100)
    purchase_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
    )
    image = models.ImageField(upload_to="clothing_items/", null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=~models.Q(name=""),
                name="clothing_item_name_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(category=""),
                name="clothing_item_category_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(season=""),
                name="clothing_item_season_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(occasion=""),
                name="clothing_item_occasion_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(size=""),
                name="clothing_item_size_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(material=""),
                name="clothing_item_material_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(brand=""),
                name="clothing_item_brand_not_empty",
            ),
            models.CheckConstraint(
                condition=~models.Q(image=""),
                name="clothing_item_image_not_empty",
            ),
        ]

    def __str__(self):
        return f"{self.name} ({self.owner.username})"

    def save(self, *args, **kwargs):
        # If the image is being replaced, delete the old file after a successful save.
        old_image = None
        if self.pk:
            try:
                old_image = ClothingItem.objects.only("image").get(pk=self.pk).image
            except ClothingItem.DoesNotExist:
                old_image = None

        super().save(*args, **kwargs)

        if old_image and self.image and old_image.name != self.image.name:
            old_image.delete(save=False)

    def delete(self, *args, **kwargs):
        image = self.image
        super().delete(*args, **kwargs)
        if image:
            image.delete(save=False)


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


class Outfit(models.Model):
    owner = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name="outfits",
    )
    name = models.CharField(max_length=150)
    occasion = models.CharField(max_length=100)
    is_public = models.BooleanField(default=False)
    items = models.ManyToManyField(
        ClothingItem,
        related_name="outfits",
        blank=True,
    )
    saved_by = models.ManyToManyField(
        Profile,
        related_name="saved_outfits",
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "name"],
                name="unique_outfit_name_per_user",
            ),
        ]

    def __str__(self):
        return f"{self.name} ({self.owner.username})"
