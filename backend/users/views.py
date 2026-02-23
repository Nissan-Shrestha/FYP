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

    item = ClothingItem.objects.create(
        owner=profile,
        name=serializer.validated_data.get("name"),
        category=serializer.validated_data.get("category", ""),
        season=serializer.validated_data.get("season", ""),
        occasion=serializer.validated_data.get("occasion", ""),
        size=serializer.validated_data.get("size", ""),
        material=serializer.validated_data.get("material", ""),
        brand=serializer.validated_data.get("brand", ""),
        image=request.FILES.get("image"),
    )

    default_wardrobe.items.add(item)

    return Response(ClothingItemSerializer(item).data, status=201)


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
