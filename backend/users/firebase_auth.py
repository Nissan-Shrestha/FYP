import os
import firebase_admin
from firebase_admin import credentials, auth
from rest_framework.response import Response
from pathlib import Path


def initialize_firebase():
    """Initialize the Firebase Admin SDK using the service account key.
    Safe to call multiple times — only initializes once.
    """
    if firebase_admin._apps:
        return  # already initialized

    key_filename = os.getenv("FIREBASE_SERVICE_ACCOUNT_KEY")
    if not key_filename:
        raise RuntimeError(
            "FIREBASE_SERVICE_ACCOUNT_KEY is not set in your .env file."
        )

    # Key file lives in the backend/ root (same folder as manage.py)
    base_dir = Path(__file__).resolve().parent.parent
    key_path = base_dir / key_filename

    if not key_path.exists():
        raise FileNotFoundError(
            f"Firebase service account key not found at: {key_path}\n"
            "Make sure the file exists and FIREBASE_SERVICE_ACCOUNT_KEY in .env is correct."
        )

    cred = credentials.Certificate(str(key_path))
    firebase_admin.initialize_app(cred)


def get_firebase_uid(request):
    """Extract and verify the Firebase ID token from the Authorization header.

    Returns:
        (firebase_uid: str, error: None)  on success
        (None, Response)                  on failure

    Usage in views:
        firebase_uid, err = get_firebase_uid(request)
        if err:
            return err
    """
    auth_header = request.headers.get("Authorization", "")

    if not auth_header.startswith("Bearer "):
        return None, Response(
            {"error": "Authorization header missing or invalid. Expected: Bearer <token>"},
            status=401,
        )

    token = auth_header.split(" ", 1)[1].strip()

    try:
        decoded = auth.verify_id_token(token)
        return decoded["uid"], None
    except auth.ExpiredIdTokenError:
        return None, Response({"error": "Token has expired. Please log in again."}, status=401)
    except auth.InvalidIdTokenError:
        return None, Response({"error": "Invalid token."}, status=401)
    except Exception as e:
        return None, Response({"error": f"Authentication failed: {str(e)}"}, status=401)
