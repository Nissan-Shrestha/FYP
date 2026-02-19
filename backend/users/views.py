from django.shortcuts import render


from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Profile
from .serializers import ProfileSerializer


@api_view(["POST"])
def get_or_create_profile(request):
    firebase_uid = request.data.get("firebase_uid")
    email = request.data.get("email")
    username = request.data.get("username")

    if not firebase_uid:
        return Response({"error": "firebase_uid is required"}, status=400)

    profile, created = Profile.objects.get_or_create(
        firebase_uid=firebase_uid
    )

    # 🔥 ALWAYS update with latest data from Flutter
    if email:
        profile.email = email

    if username:
        profile.username = username

    profile.save()


    serializer = ProfileSerializer(profile)
    return Response(serializer.data)
