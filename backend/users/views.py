from datetime import date
from django.utils import timezone
from decimal import Decimal, InvalidOperation
from PIL import Image
import io
import json
import re
from google import genai
import os
from django.db import models
import stripe

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from .firebase_auth import get_firebase_uid
from .models import ClothingItem, Profile, Wardrobe, ClothingOption, Outfit, Schedule, Report, FeaturedWardrobeRequest
from .serializers import ClothingItemSerializer, ProfileSerializer, WardrobeSerializer, ClothingOptionSerializer, OutfitSerializer, ScheduleSerializer, ReportSerializer, FeaturedWardrobeRequestSerializer

def _map_category_to_item_type(category_name):
    """
    Groups sub-categories into high-level Types (Top, Bottom, Shoes, etc.).
    Relies 100% on the Admin-managed ClothingOption database.
    """
    cat = category_name.strip()
    
    # 1. Search in Database (ClothingOption)
    option = ClothingOption.objects.filter(name__iexact=cat, type='category').first()
    
    if option and option.item_type:
        return option.item_type

    # Safe default for unrecognized categories
    return "Top"

def _map_category_to_layer(category_name):
    """
    Maps category name to a layering level (0: Base, 1: Mid, 2: Outer).
    Relies 100% on the Admin-managed ClothingOption database.
    """
    cat = category_name.strip()
    
    # 1. Search in Database (ClothingOption)
    option = ClothingOption.objects.filter(name__iexact=cat, type='category').first()
    
    if option and option.layer_level is not None:
        return option.layer_level
    
    # Default to base layer if not specified
    return 0

@api_view(["GET", "POST"])
def schedules(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    if request.method == "GET":
        date_str = request.GET.get("date")
        queryset = Schedule.objects.filter(owner=profile)
        
        if date_str:
            try:
                target_date = date.fromisoformat(date_str)
                queryset = queryset.filter(date_time__date=target_date)
            except ValueError:
                return Response({"error": "Invalid date format. Use YYYY-MM-DD"}, status=400)
                
        serializer = ScheduleSerializer(queryset, many=True, context={"request": request})
        return Response(serializer.data)

    # POST: Create a new schedule
    event_title = (request.data.get("event_title") or "").strip()
    date_time_str = request.data.get("date_time")
    outfit_id = request.data.get("outfit_id")

    if not event_title:
        return Response({"error": "Event title is required"}, status=400)
    if not date_time_str:
        return Response({"error": "Date and time are required"}, status=400)
    if not outfit_id:
        return Response({"error": "Outfit ID is required"}, status=400)

    try:
        outfit = Outfit.objects.get(id=outfit_id, owner=profile)
    except Outfit.DoesNotExist:
        return Response({"error": "Outfit not found"}, status=404)

    from django.utils.dateparse import parse_datetime
    date_time = parse_datetime(date_time_str)
    if not date_time:
        return Response({"error": "Invalid date_time format"}, status=400)

    # CHECK FOR CONFLICTS
    if Schedule.objects.filter(owner=profile, date_time=date_time).exists():
        return Response({
            "error": "You already have an outfit scheduled for this exact time and date. Please choose a different slot."
        }, status=400)

    schedule = Schedule.objects.create(
        owner=profile,
        event_title=event_title,
        date_time=date_time,
        outfit=outfit
    )

    serializer = ScheduleSerializer(schedule, context={"request": request})
    return Response(serializer.data, status=201)


@api_view(["DELETE"])
def schedule_detail(request, schedule_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    try:
        schedule = Schedule.objects.get(id=schedule_id, owner=profile)
    except Schedule.DoesNotExist:
        return Response({"error": "Schedule not found"}, status=404)

    schedule.delete()
    return Response(status=204)



@api_view(["GET", "POST"])
def outfits(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    request.user_profile = profile

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

    # Validate Outfit Composition using Type
    valid_items = ClothingItem.objects.filter(id__in=item_ids, owner=profile)
    
    has_top = any(it.item_type == "Top" for it in valid_items)
    has_bottom = any(it.item_type == "Bottom" for it in valid_items)
    
    if not has_top:
        return Response({"error": "An outfit must include at least one Top."}, status=400)
    if not has_bottom:
        return Response({"error": "An outfit must include at least one Bottom."}, status=400)

    # Optional: Layering validation (Only 1 base layer top)
    base_layer_tops = sum(1 for it in valid_items if it.item_type == "Top" and it.layer_level == 0)
    if base_layer_tops > 1:
        return Response({"error": "You should only wear one base layer shirt at a time."}, status=400)

    is_public = str(request.data.get("is_public", "false")).lower() == "true"
    
    # Create the outfit
    outfit = Outfit.objects.create(
        owner=profile,
        name=name,
        occasion=occasion,
        is_public=is_public,
    )

    outfit.items.set(valid_items)

    serializer = OutfitSerializer(outfit, context={"request": request})
    return Response(serializer.data, status=201)

import json
@api_view(["POST"])
def stylist_recommend(request):
    """
    The "Stylist Brain": Uses Gemini 1.5 Flash to recommend an outfit
    based on current weather, occasion, and user's wardrobe.
    """
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    # Limit check for Free users
    if profile.plan.lower() == "free":
        if profile.last_stylist_usage and profile.last_stylist_usage.date() == timezone.now().date():
            return Response({
                "error": "You've reached your daily limit (1 suggestion/day) for the AI Stylist. Upgrade to Premium for unlimted styling!"
            }, status=403)

    # 1. Get Context from Request
    occasion = request.data.get("occasion", "Casual")
    weather = request.data.get("weather", "Moderate") # e.g. "15°C, Sunny"
    
    # 2. Fetch User Wardrobe
    items = ClothingItem.objects.filter(owner=profile)
    if not items.exists():
        return Response({"error": "Your wardrobe is empty. Add some clothes first!"}, status=400)
    
    # 2.5 Wardrobe Completeness Check using Types
    has_top = items.filter(item_type="Top").exists()
    has_bottom = items.filter(item_type="Bottom").exists()
    has_shoes = items.filter(item_type="Shoes").exists()
    
    missing = []
    if not has_top: missing.append("a Top")
    if not has_bottom: missing.append("a Bottom")
    if not has_shoes: missing.append("Shoes")
    
    if missing:
        msg = f"Your wardrobe is incomplete for styling. You need: {', '.join(missing)}."
        return Response({"error": msg}, status=400)

    # 3. Format Wardrobe for AI
    wardrobe_data = []
    for it in items:
        wardrobe_data.append({
            "id": it.id,
            "type": it.item_type,
            "category": it.category,
            "color": it.color,
            "material": it.material,
            "layer": it.layer_level,
            "season": it.season,
            "occasion": it.occasion
        })
        
    # 4. Construct the Prompt
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return Response({"error": "Stylist is currently unavailable (API Key missing)."}, status=500)
    
    try:
        import re
        # 4.5 MODERN SDK CLIENT INITIALIZATION (Forcing v1 Production API)
        client = genai.Client(
            api_key=api_key
        )
        
        # 5. CONSTRUCT THE PROMPT
        prompt = f"""
    You are a high-end fashion AI personal stylist.
    The user wants an outfit for the following occasion: {occasion}.
    Current weather/condition: {weather}.
    
    Here is the user's wardrobe:
    {json.dumps(wardrobe_data)}
        
        Mandatory Styling Rules:
        1. Select a functional and stylish outfit from the available items.
        2. A complete outfit MUST have at least one Top and one Bottom.
        3. A complete outfit MUST have at least one pair of Shoes.
        4. LAYERING: If the weather is cool (below 18°C), try to layer a Mid-Layer (1) or Outer-Layer (2) on top of the Base Top (0).
        5. ACCESSORIES: Always look for a matching Accessory (Watch, Belt, Bag, Hat, etc.) that complements the event type and colors.
        6. COLOR HARMONY: Use classic color theory (e.g. complementary, analogous, or monochromatic) to make the user look high-end.
        7. MATERIAL INTELLIGENCE: Prioritize breathable natural fabrics (Linen/Cotton) for hot weather (>24°C) and insulating fabrics (Wool/Denim) for cold weather (<12°C). 
        8. PRACTICALITY & PROTECTION: DO NOT recommend Leather or Suede for 'Heavy Rain' or 'Snowy' conditions; they will be damaged! Instead, favor Synthetics (Polyester/Nylon) or Canvas for wet weather. Avoid 'Linen' in the cold – it's too thin.
        9. If NO GOOD OUTFIT can be formed, return an empty list for "item_ids" and a tip.
        
        Respond ONLY with a valid JSON in this format:
        {{
            "look_name": "A creative 2-3 word name for this look (e.g. 'Midnight Date', 'Corporate Power')",
            "item_ids": [list of item IDs or empty],
            "stylist_tip": "A short (1-2 sentence) tip on why this look is trendy for this specific context."
        }}
        """
        
        # 6. Run Gemini Flash Lite with Automatic Retries
        import time
        response = None
        max_retries = 3
        
        for attempt in range(max_retries):
            try:
                response = client.models.generate_content(
                    model='gemini-2.5-flash-lite',
                    contents=prompt,
                )
                break # Success! Exit the loop
            except Exception as e:
                err_str = str(e).lower()
                is_overloaded = "503" in err_str or "overloaded" in err_str or "demand" in err_str
                
                # If we have retries left and it's an overload error, wait and try again
                if attempt < max_retries - 1 and is_overloaded:
                    print(f"Stylist AI (2.5 Lite): Gemini is busy. Retrying (Attempt {attempt + 2}/{max_retries})...")
                    time.sleep(1.0) # Wait 1 second
                    continue
                
                # If we're out of retries or it's a different error, handle it
                if "429" in err_str or "rate limit" in err_str:
                    return Response({"error": "You've asked for too many styles! Please take a short break."}, status=429)
                
                print(f"Stylist AI Critical Error after {attempt + 1} attempts: {str(e)}")
                return Response({
                    "error": "The AI Stylist is in extremely high demand right now. Please try one last time in a minute!"
                }, status=503)
        
        # Clean response string (safety check)
        if not response or not response.text:
            print(f"Stylist AI Warning: Received EMPTY response from 2.5 Lite. Feedback: {response.prompt_feedback if response else 'No Response'}")
            return Response({"error": "The stylist is feeling shy right now. Try again!"}, status=500)
            
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        print(f"DEBUG: RAW AI RESPONSE -> {raw_text}")
        
        # SCRIPTED JSON EXTRACTION (The "JSON Hunter")
        try:
             # Find the first '{' and the last '}'
             start_idx = raw_text.find('{')
             end_idx = raw_text.rfind('}')
             
             if start_idx == -1 or end_idx == -1:
                 raise ValueError("No JSON block found in response")
                 
             json_str = raw_text[start_idx:end_idx+1]
             result = json.loads(json_str)
        except Exception as e:
             print(f"Stylist AI JSON Parse Error: {e}")
             return Response({"error": "The stylist got a bit confused. Try again!"}, status=500)
        
        suggested_ids = result.get("item_ids", [])
        
        # Security: Filter items to only those belonging to user
        final_items_qs = ClothingItem.objects.filter(id__in=suggested_ids, owner=profile)
        
        # Update usage timestamp
        profile.last_stylist_usage = timezone.now()
        profile.save(update_fields=["last_stylist_usage"])

        return Response({
            "look_name": result.get("look_name", "Curated Look"),
            "items": ClothingItemSerializer(final_items_qs, many=True, context={"request": request}).data,
            "stylist_tip": result.get("stylist_tip", "Stay stylish!")
        })
        
    except Exception as e:
        print(f"Stylist AI Error: {str(e)}")
        return Response({"error": "The stylist is having trouble deciding. Try again later!"}, status=500)

@api_view(['POST'])
def wardrobe_analysis(request):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    
    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response
    
    # 1. HARD LIMIT CHECK (Free Users: 1 per day)
    if not profile.can_use_analysis:
        return Response({
            "error": f"Daily limit reached. Available in {profile.analysis_available_in}.",
            "available_in": profile.analysis_available_in
        }, status=403)

    # 2. GATHER WARDROBE DATA
    items = ClothingItem.objects.filter(owner=profile)
    if not items.exists():
        return Response({"error": "Add some clothes to your wardrobe first so I can analyze them!"}, status=400)

    style_preference = request.data.get("style_preference", "Unisex")

    wardrobe_list = []
    for item in items:
        wardrobe_list.append({
            "type": item.item_type,
            "category": item.category,
            "color": item.color,
            "occasion": item.occasion,
            "layer": item.layer_level,
            "material": item.material,
            "season": item.season,
        })

    # 3. CONSTRUCT PROMPT
    prompt = f"""
    Act as a professional fashion consultant and wardrobe auditor.
    Analyze the user's current collection and provide a professional summary of what they are missing.
    The user's preferred style aesthetic is: '{style_preference}'.
    Base your audit and "gaps" on making their wardrobe perfect for this specific '{style_preference}' style.
    Identify gaps in categories, colors, or occasions.
    
    User's Collection Summary:
    {json.dumps(wardrobe_list)}

    Output Format (STRICT JSON):
    {{
      "overview": "A brief summary of their current style based on the collection counts.",
      "gaps": ["List item 1", "List item 2", "List item 3"],
      "recommendations": ["Product advice 1", "Product advice 2"],
      "stylist_score": 85
    }}
    
    Rules:
    - Focus on 'Essential Gaps' (e.g. 'You have no Outerwear', or 'Too much Black, try some Navy').
    - CORE AUDIT: Check if any fundamental categories are COMPLETELY MISSING (Tops, Bottoms, or Shoes). If a user has zero items in a core category, this MUST be the top priority in your 'gaps' and 'recommendations'.
    - ACCESSORIES: Specifically look for a lack of accessories (watches, bags, hats, belts) that would elevate their preferred aesthetic. Suggest missing pieces that would complete their looks.
    - Keep tips concise and extremely professional.
    - Result MUST be valid JSON.
    """

    # 4. AI INVOCATION
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return Response({"error": "Analysis is currently unavailable (API Key missing)."}, status=500)
    
    try:
        client = genai.Client(api_key=api_key)
        
        # Simple retry logic
        import time
        response = None
        for attempt in range(3):
            try:
                response = client.models.generate_content(
                    model='gemini-2.5-flash-lite',
                    contents=prompt,
                )
                break
            except:
                if attempt == 2: raise
                time.sleep(1)

        if not response or not response.text:
             return Response({"error": "The stylist is silent. Try again later!"}, status=500)

        # JSON Extraction
        raw_text = response.text.replace("```json", "").replace("```", "").strip()
        start_idx = raw_text.find('{')
        end_idx = raw_text.rfind('}')
        if start_idx == -1 or end_idx == -1:
            raise ValueError("Invalid JSON response from AI")
            
        result = json.loads(raw_text[start_idx:end_idx+1])

        # 5. SUCCESS! Update usage timestamp
        profile.last_analysis_usage = timezone.now()
        profile.save(update_fields=["last_analysis_usage"])

        return Response(result)

    except Exception as e:
        print(f"Wardrobe Analysis Error: {str(e)}")
        return Response({"error": "Analysis failed. Please try again in a bit!"}, status=500)



@api_view(["PATCH", "DELETE"])
def outfit_detail(request, outfit_id):
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    request.user_profile = profile

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
    from django.core.paginator import Paginator
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)
    if profile:
        request.user_profile = profile

    outfits = Outfit.objects.filter(is_public=True).order_by('-created_at')
    
    # Apply Filters
    occasion = request.GET.get("occasion")
    if occasion:
        outfits = outfits.filter(occasion__iexact=occasion)
    
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
        
        # Block self-saving
        if outfit.owner == profile:
            return Response({"error": "You cannot save your own outfit. It's already in your collection!"}, status=400)
        
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
    
    return Response({
        "occasions": sorted(occasions)
    }, status=200)
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


def _is_profile_social_locked(profile):
    """
    Checks if a profile is 'locked' from updating social links because it has 
    an active featured request (Pending or recently Approved).
    """
    from datetime import timedelta
    from django.utils import timezone
    three_days_ago = timezone.now() - timedelta(days=1)
    
    return FeaturedWardrobeRequest.objects.filter(
        requester=profile
    ).filter(
        models.Q(status='pending', is_paid=True) | 
        models.Q(status='approved', updated_at__gte=three_days_ago)
    ).exists()


@api_view(["GET", "POST", "PATCH"])
def get_or_create_profile(request):
    try:
        print(f"\n--- LOG: Profile Request Received [{request.method}] ---", flush=True)
        firebase_uid, err = get_firebase_uid(request)
        if err:
            print(f"--- LOG: Auth Error: {err.data} ---", flush=True)
            return err

        print(f"--- LOG: UID verified: {firebase_uid} ---", flush=True)

        # Use defaults to prevent IntegrityError on fresh signup
        initial_email = request.data.get("email", f"{firebase_uid[:10]}@example.com")
        initial_username = request.data.get("username", f"user_{firebase_uid[:8]}")
        fcm_token = request.data.get("fcm_token")

        print(f"--- LOG: Attempting get_or_create for {firebase_uid}... ---", flush=True)
        profile, created = Profile.objects.get_or_create(
            firebase_uid=firebase_uid,
            defaults={
                "email": initial_email,
                "username": initial_username,
                "fcm_token": fcm_token,
            }
        )

        if not created and fcm_token:
            profile.fcm_token = fcm_token
            profile.save()

        # Ensure every user has the required default wardrobe.
        _ensure_default_wardrobe(profile)

        # Update fields based on request method
        if request.method in ["POST", "PATCH"]:
            email = request.data.get("email")
            username = request.data.get("username")
            if email:
                profile.email = email
            if username:
                profile.username = username

            # HANDLE IMAGE UPLOAD (works for both)
            if request.FILES.get("profile_picture"):
                profile.profile_picture = request.FILES["profile_picture"]

            # HANDLE NEW FIELDS
            if "bio" in request.data:
                profile.bio = request.data["bio"]
            if "social_links" in request.data:
                if _is_profile_social_locked(profile):
                    return Response({"error": "Social links cannot be updated while you have an active or pending wardrobe feature request."}, status=403)
                
                social_links = request.data["social_links"]
                if isinstance(social_links, str):
                    try:
                        profile.social_links = json.loads(social_links)
                    except json.JSONDecodeError:
                        pass
                elif isinstance(social_links, dict):
                    profile.social_links = social_links

            profile.save()

        serializer = ProfileSerializer(profile, context={"request": request})
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print("\n!!! ERROR IN get_or_create_profile !!!")
        print(traceback.format_exc())
        return Response({"error": str(e)}, status=500)


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

    # Limit Check for Free Plan
    if profile.plan.lower() == "free" and profile.clothing_items.count() >= 25:
        return Response({
            "error": "Free plan limit reached (25 items). Please upgrade to Premium for unlimited storage!"
        }, status=403)

    default_wardrobe = _ensure_default_wardrobe(profile)

    serializer = ClothingItemSerializer(data=request.data, context={"request": request})
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)

    # Determine item type/layering early to adjust requirements
    required_fields = [
        "name",
        "category",
        "season",
        "occasion",
        "size",
        "material",
        "color",
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

    # Extract core fields and determine type/layering
    category = serializer.validated_data.get("category", "")
    item_type = _map_category_to_item_type(category)
    layer_level = _map_category_to_layer(category)
    
    # Process image (Background removal)
    processed_image = _process_background_removal(request.FILES.get("image"))
    
    # NEW: Prioritize user-selected color from Flutter app. 
    # detection is now just a fallback if needed for legacy/testing.
    color = serializer.validated_data.get("color")
    if not color:
        color = "Black" # Safe Default

    item = ClothingItem.objects.create(
        owner=profile,
        name=serializer.validated_data.get("name"),
        item_type=item_type,
        category=category,
        season=serializer.validated_data.get("season", ""),
        occasion=serializer.validated_data.get("occasion", ""),
        size=serializer.validated_data.get("size", ""),
        material=serializer.validated_data.get("material", ""),
        color=color,
        brand=serializer.validated_data.get("brand", ""),
        purchase_price=serializer.validated_data.get("purchase_price"),
        image=processed_image,
        layer_level=layer_level,
        purchase_link=request.data.get("purchase_link"),
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
        if _is_item_locked(item):
            return Response({"error": "This item belongs to a wardrobe that is currently featured or pending review and cannot be modified."}, status=403)
            
        fields = ["name", "category", "season", "occasion", "size", "material", "color", "brand"]
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

        if request.FILES.get("image"):
            item.image = _process_background_removal(request.FILES["image"])

        if "purchase_link" in request.data:
            item.purchase_link = request.data.get("purchase_link")

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

    if _is_item_locked(item):
        return Response({"error": "This item belongs to a wardrobe that is currently featured or pending review and cannot be deleted."}, status=403)

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

    # Limit Check for Free Plan
    # Only count non-default wardrobes towards the 5-wardrobe limit? 
    # Or total? The Plan Screen just said "5 Wardrobes". 
    # I'll count total (including default).
    if profile.plan.lower() == "free" and profile.wardrobes.count() >= 5:
        return Response({
            "error": "Free plan limit reached (5 wardrobes). Please upgrade to Premium for unlimited storage!"
        }, status=403)

    name = (request.data.get("name") or "").strip()
    if not name:
        return Response({"error": "name is required"}, status=400)

    if name.lower() == DEFAULT_WARDROBE_NAME:
        return Response({"error": "default wardrobe already exists"}, status=400)

    if Wardrobe.objects.filter(owner=profile, name__iexact=name).exists():
        return Response({"error": "Wardrobe name already exists"}, status=400)

    wardrobe = Wardrobe.objects.create(owner=profile, name=name, is_default=False)
    return Response(WardrobeSerializer(wardrobe, context={"request": request}).data, status=201)


def _is_wardrobe_locked(wardrobe):
    """
    Checks if a wardrobe is 'locked' because it has an active featured request.
    A wardrobe is locked if it is PENDING or recently APPROVED.
    """
    from datetime import timedelta
    three_days_ago = timezone.now() - timedelta(days=1)
    
    return FeaturedWardrobeRequest.objects.filter(
        wardrobe=wardrobe
    ).filter(
        models.Q(status='pending', is_paid=True) | 
        models.Q(status='approved', updated_at__gte=three_days_ago)
    ).exists()


def _is_item_locked(item):
    """
    Checks if an item is 'locked' because it belongs to at least one locked wardrobe.
    """
    for wardrobe in item.wardrobes.all():
        if _is_wardrobe_locked(wardrobe):
            return True
    return False


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

    if _is_wardrobe_locked(wardrobe):
        return Response({"error": "This wardrobe is currently featured or pending review and cannot be renamed."}, status=403)

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

    if _is_wardrobe_locked(wardrobe):
        return Response({"error": "This wardrobe is currently featured or pending review and cannot be modified."}, status=403)

    item_ids = request.data.get("item_ids", [])
    if not isinstance(item_ids, list):
        item_ids = []

    # Support single item_id for backward compatibility
    single_item_id = request.data.get("item_id")
    if single_item_id:
        item_ids.append(single_item_id)

    if not item_ids:
        return Response({"error": "item_id or item_ids is required"}, status=400)

    # Bulk fetch items owned by profile
    items = ClothingItem.objects.filter(id__in=item_ids, owner=profile)
    if not items.exists():
        return Response({"error": "No valid clothing items found"}, status=404)

    wardrobe.items.add(*items)
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

    if _is_wardrobe_locked(wardrobe):
        return Response({"error": "This wardrobe is currently featured or pending review and cannot be modified."}, status=403)

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

    from django.db.models import Count
    
    stats = {
        "total_users": Profile.objects.count(),
        "total_clothing_items": ClothingItem.objects.count(),
        "total_wardrobes": Wardrobe.objects.count(),
        "premium_users": Profile.objects.filter(plan__iexact="Premium").count(),
        "total_public_outfits": Outfit.objects.filter(is_public=True).count(),
        "total_saves": Outfit.objects.filter(is_public=True).aggregate(total=Count('saved_by'))['total'] or 0,
        "pending_reports": Report.objects.filter(status='pending').count(),
        "pending_feature_requests": FeaturedWardrobeRequest.objects.filter(status='pending', is_paid=True).count(),
        "total_schedules": Schedule.objects.count(),
    }

    # Get the 5 most recent profiles based on ID (as proxy for signup time)
    recent_users_qs = Profile.objects.all().order_by("-id")[:5]
    users_data = ProfileSerializer(recent_users_qs, many=True, context={"request": request}).data

    # Get top 5 popular public outfits
    top_outfits_qs = Outfit.objects.filter(is_public=True).annotate(
        saves=Count('saved_by')
    ).order_by('-saves')[:5]
    top_outfits_data = OutfitSerializer(top_outfits_qs, many=True, context={"request": request}).data

    return Response({
        "stats": stats,
        "recent_users": users_data,
        "top_outfits": top_outfits_data,
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


@api_view(["POST", "PATCH", "DELETE"])
def admin_options_manage(request, option_id=None):
    """Create, Update, or Delete clothing options. Admin only."""
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

    elif request.method == "PATCH":
        if not option_id:
            return Response({"error": "Option ID required"}, status=400)
        try:
            optionTarget = ClothingOption.objects.get(id=option_id)
            serializer = ClothingOptionSerializer(optionTarget, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=400)
        except ClothingOption.DoesNotExist:
            return Response({"error": "Option not found"}, status=404)

    elif request.method == "DELETE":
        if not option_id:
            return Response({"error": "Option ID required"}, status=400)
        try:
            optionTarget = ClothingOption.objects.get(id=option_id)
            
            # SAFE DELETE LOGIC:
            # If we delete a category/season/etc, find all items using that name and set them to "Other"
            # This prevents the mobile app from crashing on orphaned data.
            field_map = {
                'category': 'category',
                'season': 'season',
                'occasion': 'occasion',
                'size': 'size',
                'material': 'material',
                'color': 'color'
            }
            
            if optionTarget.type in field_map:
                field_name = field_map[optionTarget.type]
                filter_args = {f"{field_name}__iexact": optionTarget.name}
                update_args = {field_name: "Other"}
                ClothingItem.objects.filter(**filter_args).update(**update_args)

            optionTarget.delete()
            return Response({"message": "Option deleted and items re-assigned to 'Other' where necessary."})
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

    from rest_framework.pagination import PageNumberPagination
    queryset = Profile.objects.all().order_by("-id")
    
    paginator = PageNumberPagination()
    paginator.page_size = 10
    result_page = paginator.paginate_queryset(queryset, request)
    
    serializer = ProfileSerializer(result_page, many=True, context={"request": request})
    return paginator.get_paginated_response(serializer.data)


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

    # Protect superadmins from being modified by non-superadmins
    if user_to_update.is_superadmin and not profile_req.is_superadmin:
        return Response({"error": "Only a superadmin can modify another superadmin."}, status=403)

    # Basic updates
    if "username" in request.data:
        user_to_update.username = request.data["username"]
    
    if "plan" in request.data:
        user_to_update.plan = request.data["plan"]
        
    if "is_admin" in request.data:
        # Prevent demoting a superadmin
        if user_to_update.is_superadmin:
            return Response({"error": "Superadmins cannot be demoted."}, status=403)
        user_to_update.is_admin = bool(request.data["is_admin"])

    user_to_update.save()
    serializer = ProfileSerializer(user_to_update, context={"request": request})
    return Response(serializer.data)


@api_view(["DELETE"])
def admin_user_delete(request, firebase_uid):
    """
    Permanently deletes a user from both Django DB and Firebase Auth.
    Admin access only. Superadmins cannot be deleted.
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
        user_to_delete = Profile.objects.get(firebase_uid=firebase_uid)
    except Profile.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    # Prevent deleting superadmins
    if user_to_delete.is_superadmin:
        return Response({"error": "Superadmins cannot be deleted."}, status=403)

    # Prevent admins from deleting themselves
    if user_to_delete.firebase_uid == profile_req.firebase_uid:
        return Response({"error": "You cannot delete your own account from the admin panel."}, status=403)

    deleted_username = user_to_delete.username

    # 1. Delete profile picture file if exists
    if user_to_delete.profile_picture:
        user_to_delete.profile_picture.delete(save=False)

    # 2. Delete all clothing item images
    for item in ClothingItem.objects.filter(owner=user_to_delete):
        if item.image:
            item.image.delete(save=False)

    # 3. Delete Django profile (cascades to wardrobes, outfits, schedules, etc.)
    user_to_delete.delete()

    # 4. Delete from Firebase Auth
    try:
        from firebase_admin import auth
        auth.revoke_refresh_tokens(firebase_uid)
        auth.delete_user(firebase_uid)
    except Exception as e:
        # Profile is already deleted from DB, log the Firebase error
        print(f"Warning: Could not delete Firebase user {firebase_uid}: {e}")

    return Response({"message": f"User '{deleted_username}' has been permanently deleted."})


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

    from .models import Outfit
    
    wardrobes_qs = Wardrobe.objects.filter(owner=target_profile)
    items_qs = ClothingItem.objects.filter(owner=target_profile)
    outfits_qs = Outfit.objects.filter(owner=target_profile)

    return Response({
        "profile": ProfileSerializer(target_profile, context={"request": request}).data,
        "wardrobes": WardrobeSerializer(wardrobes_qs, many=True, context={"request": request}).data,
        "items": ClothingItemSerializer(items_qs, many=True, context={"request": request}).data,
        "outfits": OutfitSerializer(outfits_qs, many=True, context={"request": request}).data,
    })


@api_view(["POST"])
def create_report(request):
    """
    Creates a new report for an outfit.
    """
    
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)
    
    outfit_id = request.data.get("outfit_id")
    reason = request.data.get("reason")
    
    if not outfit_id or not reason:
        return Response({"error": "outfit_id and reason are required"}, status=400)
        
    try:
        outfit = Outfit.objects.get(id=outfit_id)
        
        # Block self-reporting
        if outfit.owner == profile:
            return Response({"error": "You cannot report your own outfit."}, status=400)

        report = Report.objects.create(
            reporter=profile,
            outfit=outfit,
            reason=reason
        )
        return Response({"message": "Report submitted successfully"}, status=201)
    except Outfit.DoesNotExist:
        return Response({"error": "Outfit not found"}, status=404)


@api_view(["GET"])
def admin_report_list(request):
    """
    Lists all reports. Admin only.
    """
    
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)
    
    if not profile.is_admin:
        return Response({"error": "Admin access required"}, status=403)
        
    from rest_framework.pagination import PageNumberPagination
    queryset = Report.objects.all().order_by("-created_at")
    
    paginator = PageNumberPagination()
    paginator.page_size = 10
    result_page = paginator.paginate_queryset(queryset, request)
    
    serializer = ReportSerializer(result_page, many=True, context={"request": request})
    return paginator.get_paginated_response(serializer.data)


@api_view(["POST"])
def admin_report_action(request, report_id):
    """
    Takes an action on a report. Admin only.
    Actions: 'ignore', 'resolve', 'delete_outfit'
    """
    
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)
    
    if not profile.is_admin:
        return Response({"error": "Admin access required"}, status=403)
        
    try:
        report = Report.objects.get(id=report_id)
        action = request.data.get("action")
        
        if action == "ignore":
            report.status = "ignored"
            report.save()
        elif action == "resolve":
            report.status = "resolved"
            report.save()
        elif action == "delete_outfit":
            if report.outfit:
                report.outfit.delete()
            report.status = "resolved"
            report.save()
        else:
            return Response({"error": "Invalid action"}, status=400)
            
        return Response({
            "message": f"Report {action} successfully",
            "status": report.status
        })
    except Report.DoesNotExist:
        return Response({"error": "Report not found"}, status=404)


@api_view(["GET"])
def admin_report_view(request, report_id):
    """
    Returns single report details. Admin only.
    """
    
    
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)
    
    if not profile.is_admin:
        return Response({"error": "Admin access required"}, status=403)
        
    try:
        report = Report.objects.get(id=report_id)
        serializer = ReportSerializer(report, context={"request": request})
        return Response(serializer.data, status=200)
    except Report.DoesNotExist:
        return Response({"error": "Report not found"}, status=404)


@api_view(["POST"])
def admin_moderation_reset(request, firebase_uid):
    """
    Resets a user's data for moderation purposes.
    Targets: 'username', 'avatar'
    """
    firebase_uid_req, err = get_firebase_uid(request)
    if err:
        return err
    profile_req, _ = _get_profile_by_firebase_uid(firebase_uid_req)
    
    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)
        
    try:
        target_profile = Profile.objects.get(firebase_uid=firebase_uid)

        # Protect superadmins from moderation
        if target_profile.is_superadmin:
            return Response({"error": "Superadmins cannot be moderated."}, status=403)

        target = request.data.get("target")
        
        if target == "username":
            target_profile.username = f"User_{target_profile.id}"
            target_profile.save()
        elif target == "avatar":
            if target_profile.profile_picture:
                target_profile.profile_picture.delete(save=False)
                target_profile.profile_picture = None
                target_profile.save()
        else:
            return Response({"error": "Invalid target"}, status=400)
            
        return Response({"message": f"User {target} reset successfully"})
    except Profile.DoesNotExist:
        return Response({"error": "User not found"}, status=404)





@api_view(["GET", "POST"])
def featured_wardrobe_requests(request):
    """
    User-managed featured wardrobe requests. 
    POST: Create a new request.
    GET: List user's requests.
    """
    

    firebase_uid, err = get_firebase_uid(request)
    if err: return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)

    if request.method == "GET":
        from datetime import timedelta
        # Limit to 3 days for Approved/Rejected, but show ALL Pending that are actually PAID
        three_days_ago = timezone.now() - timedelta(days=1)
        queryset = FeaturedWardrobeRequest.objects.filter(requester=profile, is_paid=True).filter(
            models.Q(status='pending') | models.Q(updated_at__gte=three_days_ago)
        ).order_by("-created_at")
        
        serializer = FeaturedWardrobeRequestSerializer(queryset, many=True)
        return Response(serializer.data)

    # POST: Create request
    wardrobe_id = request.data.get("wardrobe_id")
    if not wardrobe_id:
        return Response({"error": "wardrobe_id is required"}, status=400)

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id, owner=profile)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)

    # Prevent duplicates if a request is PENDING or if an APPROVED request is still within the 3-day window
    from datetime import timedelta
    three_days_ago = timezone.now() - timedelta(days=1)
    
    active_request = FeaturedWardrobeRequest.objects.filter(
        requester=profile, 
        wardrobe=wardrobe
    ).filter(
        models.Q(status='pending', is_paid=True) | 
        models.Q(status='approved', updated_at__gte=three_days_ago)
    ).exists()

    if active_request:
        return Response({"error": "This wardrobe is already featured or has a pending request."}, status=400)

    feat_request = FeaturedWardrobeRequest.objects.create(
        requester=profile,
        wardrobe=wardrobe
    )
    return Response(FeaturedWardrobeRequestSerializer(feat_request).data, status=201)


@api_view(["GET", "DELETE"])
def featured_wardrobe_request_detail(request, request_id):
    """
    Manage an individual featured wardrobe request.
    """
    

    firebase_uid, err = get_firebase_uid(request)
    if err: return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)

    try:
        feat_req = FeaturedWardrobeRequest.objects.get(id=request_id, requester=profile)
    except FeaturedWardrobeRequest.DoesNotExist:
        return Response({"error": "Request not found"}, status=404)

    if request.method == "GET":
        return Response(FeaturedWardrobeRequestSerializer(feat_req).data)

    # DELETE: Cancel request
    if feat_req.status != "pending":
        return Response({"error": "Only pending requests can be cancelled."}, status=400)
    
    feat_req.delete()
    return Response(status=204)


@api_view(["GET"])
def featured_wardrobe_discovery(request):
    """
    Returns lookbooks (wardrobes) that have been approved as featured.
    Used on the Explore Screen.
    """
    

    from datetime import timedelta
    three_days_ago = timezone.now() - timedelta(days=1)
    
    approved_requests = FeaturedWardrobeRequest.objects.filter(
        status="approved", 
        updated_at__gte=three_days_ago
    ).order_by("-updated_at")
    
    results = []
    for req in approved_requests:
        # Get first 4 items for preview
        preview_items = req.wardrobe.items.all()[:4]
        preview_data = ClothingItemSerializer(preview_items, many=True, context={"request": request}).data

        results.append({
            "request_id": req.id,
            "wardrobe": WardrobeSerializer(req.wardrobe, context={"request": request}).data,
            "preview_items": preview_data,
            "admin_feedback": req.admin_feedback,
            "owner": ProfileSerializer(req.requester, context={"request": request}).data
        })
    
    return Response(results)


@api_view(["POST"])
def create_featured_wardrobe_payment_intent(request):
    """
    Step 1 of Feature Request: Create a Stripe PaymentIntent.
    Returns client_secret to the mobile app.
    """
    firebase_uid, err = get_firebase_uid(request)
    if err: return err
    profile, _ = _get_profile_by_firebase_uid(firebase_uid)

    wardrobe_id = request.data.get("wardrobe_id")
    if not wardrobe_id:
        return Response({"error": "wardrobe_id is required"}, status=400)

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id, owner=profile)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)

    # NEW: Ensure wardrobe is not empty before allowing feature request
    if wardrobe.items.count() == 0:
        return Response({"error": "You cannot feature an empty wardrobe. Add some items first!"}, status=400)

    from datetime import timedelta
    three_days_ago = timezone.now() - timedelta(days=1)

    # Check for active requests that are actually PAID or recently APPROVED.
    # We ignore unpaid 'pending' requests because those are likely cancelled/stuck attempts.
    active_request = FeaturedWardrobeRequest.objects.filter(
        requester=profile, 
        wardrobe=wardrobe
    ).filter(
        models.Q(status='pending', is_paid=True) | 
        models.Q(status='approved', updated_at__gte=three_days_ago)
    ).first()

    if active_request:
        return Response({"error": "This wardrobe is already featured or has an active paid request."}, status=400)

    # Clean up any old unpaid requests for this wardrobe so we don't clutter the DB
    FeaturedWardrobeRequest.objects.filter(requester=profile, wardrobe=wardrobe, is_paid=False).delete()

    # 2. Setup Stripe
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    if not stripe.api_key:
        return Response({"error": "Stripe is not configured on the server."}, status=500)

    try:
        # Amount in cents ($1.99 = 199 cents)
        amount = 199 
        
        # 3. Create Stripe PaymentIntent (Restricted to cards only)
        intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='usd',
            payment_method_types=['card'],
            metadata={
                'profile_id': str(profile.id),
                'wardrobe_id': str(wardrobe.id),
                'type': 'featured_wardrobe'
            }
        )

        # 4. Create UNPAID request placeholder
        # This will be marked as paid=True by the webhook later
        feat_request = FeaturedWardrobeRequest.objects.create(
            requester=profile,
            wardrobe=wardrobe,
            is_paid=False,
            stripe_payment_intent_id=intent.id
        )

        return Response({
            'client_secret': intent.client_secret,
            'payment_intent_id': intent.id,
            'request_id': feat_request.id
        })

    except Exception as e:
        return Response({'error': str(e)}, status=400)


@api_view(["POST"])
def create_premium_payment_intent(request):
    """
    Creates a Stripe PaymentIntent for a Premium Subscription ($4.99).
    """
    firebase_uid, err = get_firebase_uid(request)
    if err:
        return err

    profile, error_response = _get_profile_by_firebase_uid(firebase_uid)
    if error_response:
        return error_response

    # 1. Setup Stripe
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
    if not stripe.api_key:
        return Response({"error": "Stripe is not configured on the server."}, status=500)

    try:
        # Amount in cents ($4.99 = 499 cents)
        amount = 499 
        
        # 2. Create Stripe PaymentIntent
        intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='usd',
            payment_method_types=['card'],
            metadata={
                'profile_id': str(profile.id),
                'type': 'premium_subscription'
            }
        )

        return Response({
            'client_secret': intent.client_secret,
            'payment_intent_id': intent.id,
        })

    except Exception as e:
        return Response({'error': str(e)}, status=400)


@api_view(["POST"])
@permission_classes([AllowAny])
def stripe_webhook(request):
    """
    Stripe Webhook: Matches PaymentIntent with WardrobeRequest and marks as PAID.
    """
    payload = request.body
    sig_header = request.headers.get('STRIPE_SIGNATURE')
    endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

    if not sig_header or not endpoint_secret:
        print(f"WEBHOOK ERROR: Missing sig_header ({bool(sig_header)}) or endpoint_secret ({bool(endpoint_secret)})", flush=True)
        return Response({"error": "Webhook configuration missing"}, status=400)

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except ValueError as e:
        print(f"WEBHOOK ERROR: Invalid payload - {e}", flush=True)
        return Response({"error": "Invalid payload"}, status=400)
    except stripe.error.SignatureVerificationError as e:
        print(f"WEBHOOK ERROR: Invalid signature - {e}", flush=True)
        print(f"Signature Header: {sig_header[:20]}...", flush=True)
        print(f"Secret used: {endpoint_secret[:5]}...", flush=True)
        return Response({"error": "Invalid signature"}, status=400)

    # Handle the event
    if event.type == 'payment_intent.succeeded':
        intent = event.data.object
        payment_intent_id = intent.id

        try:
            # Check type from metadata
            metadata = getattr(intent, 'metadata', {})
            event_type = getattr(metadata, 'type', None)
            
            print(f"WEBHOOK: Event type recognized as {event_type}", flush=True)

            if event_type == 'featured_wardrobe':
                feat_req = FeaturedWardrobeRequest.objects.get(stripe_payment_intent_id=payment_intent_id)
                feat_req.is_paid = True
                feat_req.save()
                print(f"WEBHOOK SUCCESS: Featured Wardrobe Request {feat_req.id} marked as PAID.", flush=True)
            
            elif event_type == 'premium_subscription':
                profile_id = getattr(metadata, 'profile_id', None)
                if not profile_id:
                    raise Exception("Missing profile_id in metadata")
                
                profile = Profile.objects.get(id=profile_id)
                print(f"WEBHOOK [Premium]: Found profile_id={profile_id}. Updating User {profile.username}...", flush=True)
                profile.plan = "premium"
                profile.premium_until = timezone.now() + timezone.timedelta(days=30)
                profile.save()
                print(f"WEBHOOK SUCCESS: User {profile.username} upgraded to PREMIUM for 30 days.", flush=True)

        except FeaturedWardrobeRequest.DoesNotExist:
            print(f"WEBHOOK WARNING: PaymentIntent {payment_intent_id} (featured) not found in DB.", flush=True)
        except Profile.DoesNotExist:
            print(f"WEBHOOK WARNING: Profile {getattr(metadata, 'profile_id', 'unknown')} not found in DB.", flush=True)
        except Exception as e:
            import traceback
            print(f"WEBHOOK INTERNAL ERROR: {str(e)}", flush=True)
            traceback.print_exc()

    return Response({"status": "success"}, status=200)


@api_view(["GET", "POST"])
def admin_featured_wardrobe_requests(request):
    """
    Admin-only view to manage featured wardrobe requests.
    """
    

    firebase_uid_req, err = get_firebase_uid(request)
    if err: return err
    profile_req, _ = _get_profile_by_firebase_uid(firebase_uid_req)

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    if request.method == "GET":
        status_filter = request.GET.get("status")
        queryset = FeaturedWardrobeRequest.objects.filter(is_paid=True).order_by("-created_at")
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        from rest_framework.pagination import PageNumberPagination
        paginator = PageNumberPagination()
        paginator.page_size = 10
        result_page = paginator.paginate_queryset(queryset, request)
        
        serializer = FeaturedWardrobeRequestSerializer(result_page, many=True)
        return paginator.get_paginated_response(serializer.data)

    req_id = request.data.get("request_id")
    new_status = request.data.get("status")
    feedback = request.data.get("feedback", "")

    if not req_id or not new_status:
        return Response({"error": "request_id and status are required"}, status=400)

    try:
        feat_req = FeaturedWardrobeRequest.objects.get(id=req_id, is_paid=True)
        feat_req.status = new_status
        feat_req.admin_feedback = feedback
        feat_req.save()

        if new_status == "approved":
            feat_req.requester.is_featured = True
            feat_req.requester.save()

            from .utils import send_push_notification
            send_push_notification(
                fcm_token=feat_req.requester.fcm_token,
                title="Wardrobe Approved! 🌟",
                body=f"Congratulations! Your wardrobe '{feat_req.wardrobe.name}' is now live in Discovery.",
                data={"type": "feature_approval", "request_id": str(feat_req.id)}
            )

        if new_status == "rejected":
            # Automatic Refund
            try:
                stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
                if feat_req.is_paid and feat_req.stripe_payment_intent_id:
                    stripe.Refund.create(
                        payment_intent=feat_req.stripe_payment_intent_id,
                    )
                    print(f"REFUND SUCCESS: Request {feat_req.id} refunded.")

                    from .utils import send_push_notification
                    send_push_notification(
                        fcm_token=feat_req.requester.fcm_token,
                        title="Wardrobe Review Update",
                        body=f"Your feature request for '{feat_req.wardrobe.name}' was not approved this time. A full refund has been issued.",
                        data={"type": "feature_rejection"}
                    )
            except Exception as e:
                print(f"REFUND ERROR: {str(e)}")

        return Response({"message": f"Request marked as {new_status}"})
    except FeaturedWardrobeRequest.DoesNotExist:
        return Response({"error": "Request not found"}, status=404)


@api_view(["GET"])
def admin_wardrobe_view(request, wardrobe_id):
    """
    Allows admin to view ANY wardrobe and its items for review.
    """
    

    firebase_uid_req, err = get_firebase_uid(request)
    if err: return err
    profile_req, _ = _get_profile_by_firebase_uid(firebase_uid_req)

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    try:
        wardrobe = Wardrobe.objects.get(id=wardrobe_id)
        serializer = WardrobeSerializer(wardrobe, context={"request": request})
        data = serializer.data
        
        items_queryset = wardrobe.items.all()
        data["items_details"] = ClothingItemSerializer(items_queryset, many=True, context={"request": request}).data
        
        return Response(data)
    except Wardrobe.DoesNotExist:
        return Response({"error": "Wardrobe not found"}, status=404)
