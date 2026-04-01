import os
import django

import sys

# Add project root to sys.path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from users.models import ClothingOption

def refill_options():
    print("Clearing existing ClothingOptions...")
    ClothingOption.objects.all().delete()

    options = []

    # --- CATEGORIES ---
    # format: (name, item_type, layer_level)
    categories = [
        ("T-shirt", "Top", 0),
        ("Shirt", "Top", 0),
        ("Polo Shirt", "Top", 0),
        ("Tank Top", "Top", 0),
        ("Hoodie", "Top", 1),
        ("Sweater", "Top", 1),
        ("Cardigan", "Top", 1),
        ("Sweatshirt", "Top", 1),
        ("Jacket", "Top", 2),
        ("Coat", "Top", 2),
        ("Blazer", "Top", 1),
        ("Trench Coat", "Top", 2),
        ("Vest", "Top", 1),
        ("Windbreaker", "Top", 2),
        
        # Bottoms
        ("Jeans", "Bottom", 0),
        ("Trousers", "Bottom", 0),
        ("Shorts", "Bottom", 0),
        ("Skirt", "Bottom", 0),
        ("Leggings", "Bottom", 0),
        ("Cargo Pants", "Bottom", 0),
        ("Chinos", "Bottom", 0),
        ("Sweatpants", "Bottom", 0),
        
        # Shoes
        ("Sneakers", "Shoes", 0),
        ("Boots", "Shoes", 0),
        ("Sandals", "Shoes", 0),
        ("Formal Shoes", "Shoes", 0),
        ("Heels", "Shoes", 0),
        ("Loafers", "Shoes", 0),
        
        # Accessories
        ("Watch", "Accessory", 0),
        ("Belt", "Accessory", 0),
        ("Sunglasses", "Accessory", 0),
        ("Hat", "Accessory", 0),
        ("Cap", "Accessory", 0),
        ("Scarf", "Accessory", 0),
        ("Tie", "Accessory", 0),
        
        # Bags
        ("Backpack", "Bag", 0),
        ("Handbag", "Bag", 0),
        ("Tote Bag", "Bag", 0),
    ]

    for name, item_type, layer in categories:
        options.append(ClothingOption(
            type='category', 
            name=name, 
            item_type=item_type, 
            layer_level=layer
        ))

    # --- SEASONS ---
    for season in ["Spring", "Summer", "Autumn", "Winter", "All Seasons", "Monsoon"]:
        options.append(ClothingOption(type='season', name=season))

    # --- OCCASIONS ---
    for occasion in ["Casual", "Work", "Party", "Date", "Gym", "Formal", "Wedding", "Travel"]:
        options.append(ClothingOption(type='occasion', name=occasion))

    # --- SIZES ---
    for size in ["S", "M", "L", "XL", "XXL"]:
        options.append(ClothingOption(type='size', name=size))

    # --- MATERIALS ---
    materials = [
        "Cotton", "Wool", "Linen", "Denim", "Leather", "Suede", "Silk", 
        "Cashmere", "Polyester", "Nylon", "Synthetic", "Satin", "Velvet",
        "Corduroy", "Viscose", "Rayon", "Fleece", "Jersey", "Drifit", "Flannel", "Canvas",
        "Gore-Tex (Waterproof)", "Tweed (Formal/Academic)", "Seersucker (Summer)", "Faux Fur (Luxury)", "Chenille (Cozy)"
    ]
    for material in materials:
        options.append(ClothingOption(type='material', name=material))

    # --- COLORS ---
    colors = [
        # Neutrals
        "Black", "White", "Grey", "Light Grey", "Dark Grey", "Charcoal", "Silver", "Gold",
        # Warm Tones
        "Cream", "Ivory", "Beige", "Tan", "Brown", "Dark Brown", "Camel", "Khaki",
        # Blues
        "Navy Blue", "Royal Blue", "Light Blue", "Sky Blue", "Dark Blue", "Teal", "Turquoise", "Cyan",
        # Reds & Pinks
        "Red", "Dark Red", "Maroon", "Burgundy", "Pink", "Light Pink", "Hot Pink", "Salmon", "Rose",
        # Greens
        "Green", "Light Green", "Dark Green", "Olive Green", "Forest Green", "Emerald", "Lime", "Mint",
        # Purples & Yellows
        "Purple", "Light Purple", "Deep Purple", "Yellow", "Light Yellow", "Mustard", "Orange", "Peach",
        # Special
        "Multicolor", "Floral", "Camo", "Animal Print"
    ]

    for color in colors:
        options.append(ClothingOption(type='color', name=color))

    # --- WEATHERS ---
    weathers = [
        "Clear Sky", "Hot & Sunny", "Cloudy", "Windy",
        "Light Rain", "Heavy Rain", "Thunderstorm",
        "Foggy", "Snowy", "Freezing Cold", "Moderate"
    ]
    for weather in weathers:
        options.append(ClothingOption(type='weather', name=weather))

    print(f"Refilling {len(options)} options...")
    ClothingOption.objects.bulk_create(options)
    print("Done! Database is refilled and AI-ready.")

if __name__ == "__main__":
    refill_options()
