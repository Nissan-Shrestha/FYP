from django.core.management.base import BaseCommand
from users.models import ClothingOption

class Command(BaseCommand):
    help = 'Populates the database with default clothing options'

    def handle(self, *args, **kwargs):
        options = {
            'category': [
                # TOPS
                ('T-shirt', 'Top', 0),
                ('Shirt', 'Top', 0),
                ('Polo Shirt', 'Top', 0),
                ('Tank Top', 'Top', 0),
                ('Hoodie', 'Top', 1),
                ('Sweater', 'Top', 1),
                ('Cardigan', 'Top', 1),
                ('Sweatshirt', 'Top', 1),
                ('Jacket', 'Top', 2),
                ('Coat', 'Top', 2),
                ('Blazer', 'Top', 2),
                ('Trench Coat', 'Top', 2),
                ('Vest', 'Top', 1),
                ('Windbreaker', 'Top', 2),
                
                # BOTTOMS
                ('Jeans', 'Bottom', 0),
                ('Trousers', 'Bottom', 0),
                ('Shorts', 'Bottom', 0),
                ('Skirt', 'Bottom', 0),
                ('Leggings', 'Bottom', 0),
                ('Cargo Pants', 'Bottom', 0),
                ('Chinos', 'Bottom', 0),
                ('Sweatpants', 'Bottom', 0),

                # SHOES
                ('Sneakers', 'Shoes', 0),
                ('Boots', 'Shoes', 0),
                ('Sandals', 'Shoes', 0),
                ('Formal Shoes', 'Shoes', 0),
                ('Heels', 'Shoes', 0),
                ('Loafers', 'Shoes', 0),

                # ACCESSORIES
                ('Watch', 'Accessory', 0),
                ('Belt', 'Accessory', 0),
                ('Sunglasses', 'Accessory', 0),
                ('Hat', 'Accessory', 0),
                ('Cap', 'Accessory', 0),
                ('Scarf', 'Accessory', 0),
                ('Tie', 'Accessory', 0),

                # BAGS
                ('Backpack', 'Bag', 0),
                ('Handbag', 'Bag', 0),
                ('Tote Bag', 'Bag', 0),
            ],
            'season': [
                'Spring', 'Summer', 'Autumn', 'Winter', 'All Seasons', 'Monsoon'
            ],
            'occasion': [
                'Casual', 'Work', 'Party', 'Date', 'Gym', 'Formal', 'Wedding', 'Travel',
                'Office', 'Business Casual', 'Gala', 'Black Tie', 'Beach', 'Poolside',
                'Concert', 'Festival', 'Hiking', 'Camping', 'Date Night', 'Brunch',
                'Funeral', 'Job Interview'
            ],
            'size': [
                'S', 'M', 'L', 'XL', 'XXL', 'One Size', 'N/A',
                'UK 3', 'UK 4', 'UK 5', 'UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11', 'UK 12', 'UK 13'
            ],
            'material': [
                # Clothing Fabrics
                'Cotton', 'Wool', 'Linen', 'Denim', 'Leather', 'Suede', 'Silk', 
                'Cashmere', 'Polyester', 'Nylon', 'Synthetic', 'Satin', 'Velvet', 
                'Corduroy', 'Viscose', 'Rayon', 'Fleece', 'Jersey', 'Drifit', 
                'Flannel', 'Canvas', 'Gore-Tex (Waterproof)', 'Tweed', 'Seersucker',

                # NEW: Accessory & Bag Materials
                'Metal', 'Gold', 'Silver', 'Stainless Steel', 'Silicone', 
                'Plastic', 'Resin', 'Stone', 'Beads', 'Wood', 'Straw', 'Faux Leather',
                'N/A', 'Other'
            ],
            'color': [
                'Black', 'White', 'Grey', 'Light Grey', 'Dark Grey', 'Charcoal', 
                'Silver', 'Gold', 'Cream', 'Ivory', 'Beige', 'Tan', 'Brown', 
                'Dark Brown', 'Camel', 'Khaki', 'Navy Blue', 'Royal Blue', 
                'Light Blue', 'Sky Blue', 'Dark Blue', 'Teal', 'Turquoise', 
                'Cyan', 'Red', 'Dark Red', 'Maroon', 'Burgundy', 'Pink', 
                'Light Pink', 'Hot Pink', 'Salmon', 'Rose', 'Green', 
                'Light Green', 'Dark Green', 'Olive Green', 'Forest Green', 
                'Emerald', 'Lime', 'Mint', 'Purple', 'Light Purple', 
                'Deep Purple', 'Yellow', 'Light Yellow', 'Mustard', 'Orange', 
                'Peach', 'Rust', 'Mauve', 'Terracotta', 'Champagne', 'Indigo', 'Coral',
                'Multicolor', 'Floral', 'Camo', 'Animal Print'
            ],
            'weather': [
                'Clear Sky', 'Hot & Sunny', 'Cloudy', 'Windy', 'Light Rain', 
                'Heavy Rain', 'Thunderstorm', 'Foggy', 'Snowy', 'Freezing Cold', 'Moderate'
            ]
        }

        count = 0
        for opt_type, values in options.items():
            for val in values:
                if opt_type == 'category':
                    name, item_type, layer = val
                    obj, created = ClothingOption.objects.get_or_create(
                        type=opt_type,
                        name=name,
                        defaults={'item_type': item_type, 'layer_level': layer}
                    )
                else:
                    obj, created = ClothingOption.objects.get_or_create(
                        type=opt_type,
                        name=val
                    )
                
                if created:
                    count += 1

        self.stdout.write(self.style.SUCCESS(f'Successfully added {count} new options.'))
