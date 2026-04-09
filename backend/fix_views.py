import sys

file_path = r'e:\fyp\backend\users\views.py'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Clean lines 1391 to the end (approx)
# We want to keep everything before 'def feature_request_detail' or similar
# Better: Find the first occurrence of '@api_view(["GET", "DELETE"])\ndef feature_request_detail'

start_idx = -1
for i, line in enumerate(lines):
    if '@api_view(["GET", "DELETE"])' in line and i + 1 < len(lines) and 'def feature_request_detail' in lines[i+1]:
        start_idx = i
        break

if start_idx == -1:
    print("Could not find start index")
    sys.exit(1)

new_content = lines[:start_idx]

# Add the clean functions
added_code = [
    '@api_view(["GET", "DELETE"])\n',
    'def feature_request_detail(request, request_id):\n',
    '    """\n',
    '    Manage an individual feature request.\n',
    '    """\n',
    '    from .models import FeatureRequest\n',
    '    from .serializers import FeatureRequestSerializer\n',
    '\n',
    '    firebase_uid, err = get_firebase_uid(request)\n',
    '    if err: return err\n',
    '    profile, _ = _get_profile_by_firebase_uid(firebase_uid)\n',
    '\n',
    '    try:\n',
    '        feat_req = FeatureRequest.objects.get(id=request_id, requester=profile)\n',
    '    except FeatureRequest.DoesNotExist:\n',
    '        return Response({"error": "Request not found"}, status=404)\n',
    '\n',
    '    if request.method == "GET":\n',
    '        return Response(FeatureRequestSerializer(feat_req).data)\n',
    '\n',
    '    # DELETE: Cancel request\n',
    '    if feat_req.status != "pending":\n',
    '        return Response({"error": "Only pending requests can be cancelled."}, status=400)\n',
    '    \n',
    '    feat_req.delete()\n',
    '    return Response(status=204)\n',
    '\n',
    '\n',
    '@api_view(["GET"])\n',
    'def featured_lookbooks(request):\n',
    '    """\n',
    '    Returns lookbooks (wardrobes) that have been approved as featured.\n',
    '    Used on the Explore Screen.\n',
    '    """\n',
    '    from .models import FeatureRequest\n',
    '    from .serializers import WardrobeSerializer, ClothingItemSerializer, ProfileSerializer\n',
    '\n',
    '    approved_requests = FeatureRequest.objects.filter(status="approved").order_by("-updated_at")\n',
    '    \n',
    '    results = []\n',
    '    for req in approved_requests:\n',
    '        # Get first 4 items for preview\n',
    '        preview_items = req.wardrobe.items.all()[:4]\n',
    '        preview_data = ClothingItemSerializer(preview_items, many=True, context={"request": request}).data\n',
    '\n',
    '        results.append({\n',
    '            "request_id": req.id,\n',
    '            "wardrobe": WardrobeSerializer(req.wardrobe, context={"request": request}).data,\n',
    '            "preview_items": preview_data,\n',
    '            "admin_feedback": req.admin_feedback,\n',
    '            "owner": ProfileSerializer(req.requester, context={"request": request}).data\n',
    '        })\n',
    '    \n',
    '    return Response(results)\n',
    '\n',
    '\n',
    '@api_view(["GET", "POST"])\n',
    'def admin_feature_requests(request):\n',
    '    """\n',
    '    Admin-only view to manage feature requests.\n',
    '    """\n',
    '    from .models import FeatureRequest\n',
    '    from .serializers import FeatureRequestSerializer\n',
    '\n',
    '    firebase_uid_req, err = get_firebase_uid(request)\n',
    '    if err: return err\n',
    '    profile_req, _ = _get_profile_by_firebase_uid(firebase_uid_req)\n',
    '\n',
    '    if not profile_req.is_admin:\n',
    '        return Response({"error": "Admin access required"}, status=403)\n',
    '\n',
    '    if request.method == "GET":\n',
    '        status_filter = request.GET.get("status")\n',
    '        queryset = FeatureRequest.objects.all().order_by("-created_at")\n',
    '        if status_filter:\n',
    '            queryset = queryset.filter(status=status_filter)\n',
    '        \n',
    '        serializer = FeatureRequestSerializer(queryset, many=True)\n',
    '        return Response(serializer.data)\n',
    '\n',
    '    req_id = request.data.get("request_id")\n',
    '    new_status = request.data.get("status")\n',
    '    feedback = request.data.get("feedback", "")\n',
    '\n',
    '    if not req_id or not new_status:\n',
    '        return Response({"error": "request_id and status are required"}, status=400)\n',
    '\n',
    '    try:\n',
    '        feat_req = FeatureRequest.objects.get(id=req_id)\n',
    '        feat_req.status = new_status\n',
    '        feat_req.admin_feedback = feedback\n',
    '        feat_req.save()\n',
    '\n',
    '        if new_status == "approved":\n',
    '            feat_req.requester.is_featured = True\n',
    '            feat_req.requester.save()\n',
    '\n',
    '        return Response({"message": f"Request marked as {new_status}"})\n',
    '    except FeatureRequest.DoesNotExist:\n',
    '        return Response({"error": "Request not found"}, status=404)\n',
    '\n',
    '\n',
    '@api_view(["GET"])\n',
    'def admin_wardrobe_view(request, wardrobe_id):\n',
    '    """\n',
    '    Allows admin to view ANY wardrobe and its items for review.\n',
    '    """\n',
    '    from .models import Wardrobe\n',
    '    from .serializers import WardrobeSerializer, ClothingItemSerializer\n',
    '\n',
    '    firebase_uid_req, err = get_firebase_uid(request)\n',
    '    if err: return err\n',
    '    profile_req, _ = _get_profile_by_firebase_uid(firebase_uid_req)\n',
    '\n',
    '    if not profile_req.is_admin:\n',
    '        return Response({"error": "Admin access required"}, status=403)\n',
    '\n',
    '    try:\n',
    '        wardrobe = Wardrobe.objects.get(id=wardrobe_id)\n',
    '        serializer = WardrobeSerializer(wardrobe, context={"request": request})\n',
    '        data = serializer.data\n',
    '        \n',
    '        items_queryset = wardrobe.items.all()\n',
    '        data["items_details"] = ClothingItemSerializer(items_queryset, many=True, context={"request": request}).data\n',
    '        \n',
    '        return Response(data)\n',
    '    except Wardrobe.DoesNotExist:\n',
    '        return Response({"error": "Wardrobe not found"}, status=404)\n'
]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_content)
    f.writelines(added_code)

print("Successfully fixed views.py")
