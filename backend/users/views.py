from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Profile
from .serializers import ProfileSerializer


@api_view(["POST", "PATCH"])
def get_or_create_profile(request):
    firebase_uid = request.data.get("firebase_uid")

    if not firebase_uid:
        return Response({"error": "firebase_uid is required"}, status=400)

    profile, created = Profile.objects.get_or_create(
        firebase_uid=firebase_uid
    )

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
