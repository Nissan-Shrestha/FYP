@api_view(["GET"])
def featured_lookbooks(request):
    """
    Returns lookbooks (wardrobes) that have been approved as featured.
    Used on the Explore Screen.
    """
    from .models import FeatureRequest
    from .serializers import WardrobeSerializer, ClothingItemSerializer, ProfileSerializer

    # Fetch only approved feature requests
    approved_requests = FeatureRequest.objects.filter(status='approved').order_by("-updated_at")
    
    results = []
    for req in approved_requests:
        # Get first 4 items for preview in the mobile app card
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


@api_view(["GET", "POST"])
def admin_feature_requests(request):
    """
    Admin-only view to manage feature requests.
    JSON POST: {"status": "approved"|"rejected", "feedback": "...", "request_id": ...}
    """
    from .models import FeatureRequest, Profile
    from .serializers import FeatureRequestSerializer

    firebase_uid_req, err = get_firebase_uid(request)
    if err: return err
    profile_req, _ = _get_profile_by_firebase_uid(firebase_uid_req)

    if not profile_req.is_admin:
        return Response({"error": "Admin access required"}, status=403)

    if request.method == "GET":
        status_filter = request.GET.get("status")
        queryset = FeatureRequest.objects.all().order_by("-created_at")
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        serializer = FeatureRequestSerializer(queryset, many=True)
        return Response(serializer.data)

    # POST: Action on request
    req_id = request.data.get("request_id")
    new_status = request.data.get("status")
    feedback = request.data.get("feedback", "")

    if not req_id or not new_status:
        return Response({"error": "request_id and status are required"}, status=400)

    try:
        feat_req = FeatureRequest.objects.get(id=req_id)
        feat_req.status = new_status
        feat_req.admin_feedback = feedback
        feat_req.save()

        # If approved, update the profile's is_featured status
        if new_status == "approved":
            feat_req.requester.is_featured = True
            feat_req.requester.save()
        elif new_status == "rejected":
            pass

        return Response({"message": f"Request marked as {new_status}"})
    except FeatureRequest.DoesNotExist:
        return Response({"error": "Request not found"}, status=404)
