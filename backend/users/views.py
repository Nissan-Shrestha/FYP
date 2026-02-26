from datetime import date
from decimal import Decimal, InvalidOperation

from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import ClothingItem, Profile, Wardrobe
from .serializers import ClothingItemSerializer, ProfileSerializer, WardrobeSerializer


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


@api_view(["POST", "PATCH"])
def get_or_create_profile(request):
    firebase_uid = request.data.get("firebase_uid")

    if not firebase_uid:
        return Response({"error": "firebase_uid is required"}, status=400)

    profile, created = Profile.objects.get_or_create(
        firebase_uid=firebase_uid
    )

    # Ensure every user has the required default wardrobe.
    _ensure_default_wardrobe(profile)

    #  HANDLE POST (Create or full update)
    if request.method == "POST":
        email = request.data.get("email")
        username = request.data.get("username")

        if email:
            profile.email = email

        if username:
            profile.username = username

    # HANDLE PATCH (Partial update)
    if request.method == "PATCH":
        username = request.data.get("username")
        if username:
            profile.username = username

    # HANDLE IMAGE UPLOAD (works for both)
    if request.FILES.get("profile_picture"):
        profile.profile_picture = request.FILES["profile_picture"]

    profile.save()

    serializer = ProfileSerializer(profile)
    return Response(serializer.data)


@api_view(["GET", "POST"])
def clothing_items(request):
    firebase_uid = request.query_params.get("firebase_uid") or request.data.get("firebase_uid")
    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if request.method == "GET":
        queryset = ClothingItem.objects.filter(owner=profile).order_by("-created_at")
        return Response(ClothingItemSerializer(queryset, many=True).data)

    default_wardrobe = _ensure_default_wardrobe(profile)

    serializer = ClothingItemSerializer(data=request.data)
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
        purchase_store=(serializer.validated_data.get("purchase_store", "") or "").strip(),
        purchase_price=serializer.validated_data.get("purchase_price"),
        purchase_date=serializer.validated_data.get("purchase_date"),
        image=request.FILES.get("image"),
    )

    default_wardrobe.items.add(item)

    return Response(ClothingItemSerializer(item).data, status=201)


@api_view(["PATCH", "DELETE"])
def clothing_item_detail(request, item_id):
    firebase_uid = request.query_params.get("firebase_uid") or request.data.get("firebase_uid")
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

        if "purchase_store" in request.data:
            item.purchase_store = str(request.data.get("purchase_store", "")).strip()

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
            item.image = request.FILES["image"]

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
        return Response(ClothingItemSerializer(item).data, status=200)

    item.delete()
    return Response(status=204)


@api_view(["GET", "POST"])
def wardrobes(request):
    firebase_uid = request.query_params.get("firebase_uid") or request.data.get("firebase_uid")
    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    _ensure_default_wardrobe(profile)

    if request.method == "GET":
        queryset = Wardrobe.objects.filter(owner=profile).order_by("-is_default", "name")
        return Response(WardrobeSerializer(queryset, many=True).data)

    name = (request.data.get("name") or "").strip()
    if not name:
        return Response({"error": "name is required"}, status=400)

    if name.lower() == DEFAULT_WARDROBE_NAME:
        return Response({"error": "default wardrobe already exists"}, status=400)

    if Wardrobe.objects.filter(owner=profile, name__iexact=name).exists():
        return Response({"error": "Wardrobe name already exists"}, status=400)

    wardrobe = Wardrobe.objects.create(owner=profile, name=name, is_default=False)
    return Response(WardrobeSerializer(wardrobe).data, status=201)


@api_view(["PATCH", "DELETE"])
def wardrobe_detail(request, wardrobe_id):
    firebase_uid = request.query_params.get("firebase_uid") or request.data.get("firebase_uid")
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
    return Response(WardrobeSerializer(wardrobe).data, status=200)


@api_view(["GET", "POST"])
def wardrobe_items(request, wardrobe_id):
    firebase_uid = request.query_params.get("firebase_uid") or request.data.get("firebase_uid")
    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id, owner=profile)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)

    if request.method == "GET":
        queryset = wardrobe.items.filter(owner=profile).order_by("-created_at")
        return Response(ClothingItemSerializer(queryset, many=True).data)

    item_id = request.data.get("item_id")
    if not item_id:
        return Response({"error": "item_id is required"}, status=400)

    try:
        item = ClothingItem.objects.get(id=item_id, owner=profile)
    except ClothingItem.DoesNotExist:
        return Response({"error": "Clothing item not found"}, status=404)

    wardrobe.items.add(item)
    return Response(WardrobeSerializer(wardrobe).data, status=200)


@api_view(["DELETE"])
def remove_item_from_wardrobe(request, wardrobe_id, item_id):
    firebase_uid = request.query_params.get("firebase_uid") or request.data.get("firebase_uid")
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
    return Response(WardrobeSerializer(wardrobe).data, status=200)
