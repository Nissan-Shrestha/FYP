from django.urls import path
from .views import (
    clothing_items,
    get_or_create_profile,
    remove_item_from_wardrobe,
    wardrobe_items,
    wardrobes,
)

urlpatterns = [
    path("profile/", get_or_create_profile),
    path("clothing-items/", clothing_items),
    path("wardrobes/", wardrobes),
    path("wardrobes/<int:wardrobe_id>/items/", wardrobe_items),
    path(
        "wardrobes/<int:wardrobe_id>/items/<int:item_id>/",
        remove_item_from_wardrobe,
    ),
]
