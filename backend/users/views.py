from datetime import date
from decimal import Decimal, InvalidOperation

from rest_framework.decorators import api_view
from rest_framework.response import Response
from .firebase_auth import get_firebase_uid
from .models import ClothingItem, Profile, Wardrobe, ClothingOption, Outfit
from .serializers import ClothingItemSerializer, ProfileSerializer, WardrobeSerializer, ClothingOptionSerializer, OutfitSerializer


@api_view(["GET", "POST"])
def outfits(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if request.method == "GET":
        queryset = Outfit.objects.filter(owner=profile).order_by("-created_at")
        serializer = OutfitSerializer(queryset, many=True, context={"request": request})
        return Response(serializer.data)

    # POST logic: Create a new outfit
    name = (request.data.get("name") or "").strip()
    occasion = (request.data.get("occasion") or "").strip()

    if not name:
        return Response({"error": "Outfit name is required"}, status=400)

    if not occasion:
        return Response({"error": "Occasion is required"}, status=400)

    if Outfit.objects.filter(owner=profile, name__iexact=name).exists():
        return Response({"error": "Outfit with this name already exists"}, status=400)

    item_ids = request.data.get("item_ids", [])
    if not isinstance(item_ids, list) or not item_ids:
        return Response({"error": "At least one item_id is required"}, status=400)

    if len(item_ids) < 2:
        return Response({"error": "An outfit must have at least 2 items"}, status=400)

    if len(item_ids) > 8:
        return Response({"error": "An outfit cannot have more than 8 items"}, status=400)

    is_public = str(request.data.get("is_public", "false")).lower() == "true"
    
    # Create the outfit
    outfit = Outfit.objects.create(
        owner=profile,
        name=name,
        occasion=(request.data.get("occasion") or "").strip(),
        is_public=is_public,
    )

    # Add items that belong to the user
    valid_items = ClothingItem.objects.filter(id__in=item_ids, owner=profile)
    outfit.items.set(valid_items)

    serializer = OutfitSerializer(outfit, context={"request": request})
    return Response(serializer.data, status=201)


@api_view(["PATCH", "DELETE"])
def outfit_detail(request, outfit_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        outfit = Outfit.objects.get(id=outfit_id, owner=profile)
    except Outfit.DoesNotExist:
        return Response({"error": "Outfit not found"}, status=404)

    if request.method == "PATCH":
        name = request.data.get("name")
        if name is not None:
            name_stripped = str(name).strip()
            if not name_stripped:
                return Response({"error": "Outfit name cannot be empty"}, status=400)
            if Outfit.objects.filter(owner=profile, name__iexact=name_stripped).exclude(id=outfit.id).exists():
                return Response({"error": "Outfit with this name already exists"}, status=400)
            outfit.name = name_stripped

        occasion = request.data.get("occasion")
        if occasion is not None:
            occasion_stripped = str(occasion).strip()
            if not occasion_stripped:
                return Response({"error": "Occasion cannot be empty"}, status=400)
            outfit.occasion = occasion_stripped

        if "is_public" in request.data:
            outfit.is_public = str(request.data.get("is_public", "false")).lower() == "true"

        item_ids = request.data.get("item_ids")
        if item_ids is not None:
            if not isinstance(item_ids, list) or not item_ids:
                return Response({"error": "At least one item_id is required"}, status=400)
            
            if len(item_ids) < 2:
                return Response({"error": "An outfit must have at least 2 items"}, status=400)

            if len(item_ids) > 8:
                return Response({"error": "An outfit cannot have more than 8 items"}, status=400)

            valid_items = ClothingItem.objects.filter(id__in=item_ids, owner=profile)
            if not valid_items.exists():
                return Response({"error": "Invalid item_ids provided"}, status=400)
            outfit.items.set(valid_items)

        outfit.save()
        serializer = OutfitSerializer(outfit, context={"request": request})
        return Response(serializer.data, status=200)

    outfit.delete()
    return Response(status=204)

@api_view(["GET"])
def explore_outfits(request):
    """
    Returns all public outfits from all users with pagination and optional filtering. 
    """
    from .models import Outfit
    from .serializers import OutfitSerializer
    from django.core.paginator import Paginator
    
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return Response({"error": "Unauthorized"}, status=401)
        
    outfits = Outfit.objects.filter(is_public=True).order_by('-created_at')
    
    # Apply Filters
    occasion = request.GET.get("occasion")
    season = request.GET.get("season")
    if occasion:
        outfits = outfits.filter(occasion__iexact=occasion)
    if season:
        outfits = outfits.filter(season__iexact=season)
    
    page_num = request.GET.get("page", 1)
    page_size = 10
    paginator = Paginator(outfits, page_size)
    
    try:
        page = paginator.get_page(page_num)
        serializer = OutfitSerializer(page.object_list, many=True, context={"request": request})
        return Response({
            "results": serializer.data,
            "page": page.number,
            "has_more": page.has_next()
        }, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(["POST"])
def toggle_save_outfit(request, outfit_id):
    """
    Toggles whether the current user has saved this outfit.
    """
    from .models import Outfit
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response
        
    try:
        outfit = Outfit.objects.get(id=outfit_id)
        
        if profile in outfit.saved_by.all():
            outfit.saved_by.remove(profile)
            is_saved = False
        else:
            outfit.saved_by.add(profile)
            is_saved = True
            
        return Response({
            "is_saved": is_saved,
            "saves_count": outfit.saved_by.count()
        }, status=200)
    except Outfit.DoesNotExist:
        return Response({"error": "Outfit not found"}, status=404)

@api_view(["GET"])
def get_saved_outfits(request):
    """
    Returns outfits saved by the current user.
    """
    from .serializers import OutfitSerializer
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response
        
    outfits = profile.saved_outfits.all().order_by('-created_at')
    serializer = OutfitSerializer(outfits, many=True, context={"request": request})
    return Response(serializer.data, status=200)

@api_view(["GET"])
def get_explore_filters(request):
    """
    Returns all defined occasions for filtering.
    """
    from .models import ClothingOption
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)
    
    # Get all 'occasion' type options
    occasions = list(ClothingOption.objects.filter(type='occasion').values_list('name', flat=True).distinct())
    
    return Response({"occasions": sorted(occasions)}, status=200)
from rembg import remove
from django.core.files.base import ContentFile
import io


DEFAULT_WARDROBE_NAME = "all clothes"


def _get_profile_by_firebase_uid(firebase_uid):
    if not firebase_uid:
        return None, Response({"error": "firebase_uid is required"}, status=400)

    try:
        return Profile.objects.get(firebase_uid=firebase_uid), None
    except Profile.DoesNotExist:
        return None, Response({"error": "Profile not found"}, status=404)


def _ensure_default_wardrobe(profile):
    wardrobe, _ = Wardrobe.objects.get_or_create(
        owner=profile,
        name=DEFAULT_WARDROBE_NAME,
        defaults={"is_default": True},
    )
    if not wardrobe.is_default:
        wardrobe.is_default = True
        wardrobe.save(update_fields=["is_default"])
    return wardrobe


def _parse_optional_decimal(value, field_name):
    if value is None:
        return None, None
    text = str(value).strip()
    if not text:
        return None, None
    try:
        return Decimal(text), None
    except (InvalidOperation, ValueError):
        return None, Response({"error": f"{field_name} must be a valid number"}, status=400)


def _parse_optional_date(value, field_name):
    if value is None:
        return None, None
    text = str(value).strip()
    if not text:
        return None, None
    try:
        return date.fromisoformat(text), None
    except ValueError:
        return None, Response(
            {"error": f"{field_name} must be in YYYY-MM-DD format"},
            status=400,
        )


def _process_background_removal(image_file):
    """
    Takes a Django UploadedFile, removes background using rembg,
    and returns a new ContentFile (PNG).
    """
    if not image_file:
        return None
    
    try:
        # Reset file pointer if needed
        image_file.seek(0)
        input_data = image_file.read()
        
        # Process with rembg
        output_data = remove(input_data)
        
        # Determine name (force .png for transparency)
        name = image_file.name
        if "." in name:
            name = name.rsplit(".", 1)[0] + ".png"
        else:
            name = name + ".png"
            
        return ContentFile(output_data, name=name)
    except Exception as e:
        print(f"Rembg error: {e}")
        # On failure, return original (or handle differently)
        image_file.seek(0)
        return image_file


@api_view(["POST", "PATCH"])
def get_or_create_profile(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    # Use defaults to prevent IntegrityError on fresh signup
    # We use data from request if available, otherwise placeholders
    initial_email = request.data.get("email", f"{firebase_uid[:10]}@example.com")
    initial_username = request.data.get("username", f"user_{firebase_uid[:8]}")

    profile, created = Profile.objects.get_or_create(
        firebase_uid=firebase_uid,
        defaults={
            "email": initial_email,
            "username": initial_username,
        }
    )

    # Ensure every user has the required default wardrobe.
    _ensure_default_wardrobe(profile)

    # Update fields based on request method
    if request.method == "POST":
        email = request.data.get("email")
        username = request.data.get("username")
        if email:
            profile.email = email
        if username:
            profile.username = username

    elif request.method == "PATCH":
        email = request.data.get("email")
        username = request.data.get("username")
        if email:
            profile.email = email
        if username:
            profile.username = username

    # HANDLE IMAGE UPLOAD (works for both)
    if request.FILES.get("profile_picture"):
        profile.profile_picture = request.FILES["profile_picture"]

    profile.save()

    serializer = ProfileSerializer(profile, context={"request": request})
    return Response(serializer.data)


@api_view(["GET", "POST"])
def clothing_items(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if request.method == "GET":
        queryset = ClothingItem.objects.filter(owner=profile).order_by("-created_at")
        return Response(ClothingItemSerializer(queryset, many=True, context={"request": request}).data)

    default_wardrobe = _ensure_default_wardrobe(profile)

    serializer = ClothingItemSerializer(data=request.data, context={"request": request})
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)

    required_fields = [
        "name",
        "category",
        "season",
        "occasion",
        "size",
        "material",
        "brand",
    ]
    missing_fields = [
        field
        for field in required_fields
        if not str(serializer.validated_data.get(field, "")).strip()
    ]
    if missing_fields:
        return Response(
            {"error": f"Missing required fields: {', '.join(missing_fields)}"},
            status=400,
        )

    item = ClothingItem.objects.create(
        owner=profile,
        name=serializer.validated_data.get("name"),
        category=serializer.validated_data.get("category", ""),
        season=serializer.validated_data.get("season", ""),
        occasion=serializer.validated_data.get("occasion", ""),
        size=serializer.validated_data.get("size", ""),
        material=serializer.validated_data.get("material", ""),
        brand=serializer.validated_data.get("brand", ""),
        purchase_price=serializer.validated_data.get("purchase_price"),
        image=_process_background_removal(request.FILES.get("image")),
    )

    default_wardrobe.items.add(item)

    return Response(ClothingItemSerializer(item, context={"request": request}).data, status=201)


@api_view(["PATCH", "DELETE"])
def clothing_item_detail(request, item_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        item = ClothingItem.objects.get(id=item_id, owner=profile)
    except ClothingItem.DoesNotExist:
        return Response({"error": "Clothing item not found"}, status=404)

    if request.method == "PATCH":
        fields = ["name", "category", "season", "occasion", "size", "material", "brand"]
        for field in fields:
            if field in request.data:
                value = str(request.data.get(field, "")).strip()
                if not value:
                    return Response({"error": f"{field} cannot be empty"}, status=400)
                setattr(item, field, value)

        if "purchase_price" in request.data:
            parsed_price, error_response = _parse_optional_decimal(
                request.data.get("purchase_price"),
                "purchase_price",
            )
            if error_response:
                return error_response
            item.purchase_price = parsed_price

        if "purchase_date" in request.data:
            parsed_date, error_response = _parse_optional_date(
                request.data.get("purchase_date"),
                "purchase_date",
            )
            if error_response:
                return error_response
            item.purchase_date = parsed_date

        if request.FILES.get("image"):
            item.image = _process_background_removal(request.FILES["image"])

        # Enforce required fields after partial update.
        missing = [
            field for field in fields if not str(getattr(item, field, "")).strip()
        ]
        if missing:
            return Response(
                {"error": f"Missing required fields: {', '.join(missing)}"},
                status=400,
            )
        if not item.image:
            return Response({"error": "image is required"}, status=400)

        item.save()
        return Response(ClothingItemSerializer(item, context={"request": request}).data, status=200)

    item.delete()
    return Response(status=204)


@api_view(["GET", "POST"])
def wardrobes(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    _ensure_default_wardrobe(profile)

    if request.method == "GET":
        queryset = Wardrobe.objects.filter(owner=profile).order_by("-is_default", "name")
        return Response(WardrobeSerializer(queryset, many=True, context={"request": request}).data)

    name = (request.data.get("name") or "").strip()
    if not name:
        return Response({"error": "name is required"}, status=400)

    if name.lower() == DEFAULT_WARDROBE_NAME:
        return Response({"error": "default wardrobe already exists"}, status=400)

    if Wardrobe.objects.filter(owner=profile, name__iexact=name).exists():
        return Response({"error": "Wardrobe name already exists"}, status=400)

    wardrobe = Wardrobe.objects.create(owner=profile, name=name, is_default=False)
    return Response(WardrobeSerializer(wardrobe, context={"request": request}).data, status=201)


@api_view(["PATCH", "DELETE"])
def wardrobe_detail(request, wardrobe_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id, owner=profile)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)

    if request.method == "DELETE":
        if wardrobe.is_default:
            return Response({"error": "Default wardrobe cannot be deleted"}, status=400)
        wardrobe.delete()
        return Response(status=204)

    new_name = (request.data.get("name") or "").strip()
    if not new_name:
        return Response({"error": "name is required"}, status=400)
    if wardrobe.is_default:
        return Response({"error": "Default wardrobe cannot be renamed"}, status=400)
    if new_name.lower() == DEFAULT_WARDROBE_NAME:
        return Response({"error": "default wardrobe name is reserved"}, status=400)
    if Wardrobe.objects.filter(owner=profile, name__iexact=new_name).exclude(id=wardrobe.id).exists():
        return Response({"error": "Wardrobe name already exists"}, status=400)

    wardrobe.name = new_name
    wardrobe.save(update_fields=["name", "updated_at"])
    return Response(WardrobeSerializer(wardrobe, context={"request": request}).data, status=200)


@api_view(["GET", "POST"])
def wardrobe_items(request, wardrobe_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id, owner=profile)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)

    if request.method == "GET":
        queryset = wardrobe.items.filter(owner=profile).order_by("-created_at")
        return Response(ClothingItemSerializer(queryset, many=True, context={"request": request}).data)

    item_id = request.data.get("item_id")
    if not item_id:
        return Response({"error": "item_id is required"}, status=400)

    try:
        item = ClothingItem.objects.get(id=item_id, owner=profile)
    except ClothingItem.DoesNotExist:
        return Response({"error": "Clothing item not found"}, status=404)

    wardrobe.items.add(item)
    return Response(WardrobeSerializer(wardrobe, context={"request": request}).data, status=200)


@api_view(["DELETE"])
def remove_item_from_wardrobe(request, wardrobe_id, item_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id, owner=profile)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)

    if wardrobe.is_default:
        return Response(
            {"error": "Items cannot be removed from the default wardrobe"},
            status=400,
        )

    try:
        item = ClothingItem.objects.get(id=item_id, owner=profile)
    except ClothingItem.DoesNotExist:
        return Response({"error": "Clothing item not found"}, status=404)

    wardrobe.items.remove(item)
    return Response(WardrobeSerializer(wardrobe, context={"request": request}).data, status=200)


@api_view(["GET"])
def admin_dashboard_data(request):
    """
    Consolidated view for the admin dashboard: total counts + recent signups.
    """
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if not profile.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    stats = {
        "total_users": Profile.objects.count(),
        "total_clothing_items": ClothingItem.objects.count(),
        "total_wardrobes": Wardrobe.objects.count(),
        "premium_users": Profile.objects.filter(plan__iexact="Premium").count(),
    }

    # Get the 10 most recent profiles based on ID (as proxy for signup time)
    recent_users_qs = Profile.objects.all().order_by("-id")[:10]
    users_data = ProfileSerializer(recent_users_qs, many=True, context={"request": request}).data

    return Response({
        "stats": stats,
        "recent_users": users_data,
        "admin": ProfileSerializer(profile, context={"request": request}).data
    })



@api_view(["GET"])
def admin_me(request):
    """Returns the profile of the currently logged-in admin."""
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    return Response(ProfileSerializer(profile, context={"request": request}).data)


@api_view(["GET"])
def admin_options_list(request):
    """Returns all clothing options (categories, seasons, etc.) grouped by type."""
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    
    # We allow GET even if not admin for the mobile app to use this
    options = ClothingOption.objects.all().order_by('name')
    return Response(ClothingOptionSerializer(options, many=True).data)


@api_view(["POST", "DELETE"])
def admin_options_manage(request, option_id=None):
    """Create or Delete clothing options. Admin only."""
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if not profile.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    if request.method == "POST":
        serializer = ClothingOptionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    elif request.method == "DELETE":
        if not option_id:
            return Response({"error": "Option ID required"}, status=400)
        try:
            optionTarget = ClothingOption.objects.get(id=option_id)
            optionTarget.delete()
            return Response({"message": "Option deleted"})
        except ClothingOption.DoesNotExist:
            return Response({"error": "Option not found"}, status=404)


@api_view(["GET"])
def admin_categories(request):
    """
    Returns unique categories and the number of items in each.
    Admin access only.
    """
    firebase_uid_req, err = get_firebase_uid(request)
    if err:
        return err

    profile_req, error_response = _get_profile_by_firebase_uid(firebase_uid_req)
    if error_response:
        return error_response

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    from django.db.models import Count
    categories_data = ClothingItem.objects.values("category").annotate(
        total_items=Count("id")
    ).order_by("-total_items")

    return Response(list(categories_data))



@api_view(["GET"])
def admin_user_list(request):
    """
    Returns the full list of users for the User Management page.
    """
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if not profile.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    queryset = Profile.objects.all().order_by("-id")
    serializer = ProfileSerializer(queryset, many=True, context={"request": request})
    return Response(serializer.data)


@api_view(["PATCH"])
def admin_user_update(request, firebase_uid):
    """
    Updates a user's username, plan, or is_admin role.
    Admin access only.
    """
    firebase_uid_req, err = get_firebase_uid(request)
    if err:
        return err

    profile_req, error_response = _get_profile_by_firebase_uid(firebase_uid_req)
    if error_response:
        return error_response

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    try:
        user_to_update = Profile.objects.get(firebase_uid=firebase_uid)
    except Profile.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    # Basic updates
    if "username" in request.data:
        user_to_update.username = request.data["username"]
    
    if "plan" in request.data:
        user_to_update.plan = request.data["plan"]
        
    if "is_admin" in request.data:
        # In a real app, you might prevent revoking the last admin here
        user_to_update.is_admin = bool(request.data["is_admin"])

    user_to_update.save()
    serializer = ProfileSerializer(user_to_update, context={"request": request})
    return Response(serializer.data)


@api_view(["DELETE"])
def admin_user_avatar_delete(request, firebase_uid):
    """
    Deletes (clears) a user's profile picture.
    Admin access only.
    """
    firebase_uid_req, err = get_firebase_uid(request)
    if err:
        return err

    profile_req, error_response = _get_profile_by_firebase_uid(firebase_uid_req)
    if error_response:
        return error_response

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    try:
        user_to_update = Profile.objects.get(firebase_uid=firebase_uid)
    except Profile.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    # Clear the image
    if user_to_update.profile_picture:
        user_to_update.profile_picture.delete(save=False)
        user_to_update.profile_picture = None
        user_to_update.save()

    return Response({"message": "Profile picture cleared successully."})



@api_view(["GET"])
def admin_user_view(request, firebase_uid):
    """
    Returns full details for a specific user: Wardrobes and Clothing Items.
    Admin access only.
    """
    firebase_uid_req, err = get_firebase_uid(request)
    if err:
        return err

    profile_req, error_response = _get_profile_by_firebase_uid(firebase_uid_req)
    if error_response:
        return error_response

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    try:
        target_profile = Profile.objects.get(firebase_uid=firebase_uid)
    except Profile.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    wardrobes_qs = Wardrobe.objects.filter(owner=target_profile)
    items_qs = ClothingItem.objects.filter(owner=target_profile)

    return Response({
        "profile": ProfileSerializer(target_profile, context={"request": request}).data,
        "wardrobes": WardrobeSerializer(wardrobes_qs, many=True, context={"request": request}).data,
        "items": ClothingItemSerializer(items_qs, many=True, context={"request": request}).data,
    })





