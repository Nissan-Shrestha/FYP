from firebase_admin import messaging

def send_push_notification(fcm_token, title, body, data=None):
    """
    Sends a push notification to a specific device via FCM token.
    """
    if not fcm_token:
        print("No FCM token provided, skipping notification.")
        return None

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f"Successfully sent message: {response}")
        return response
    except Exception as e:
        print(f"Error sending push notification: {e}")
        return None
