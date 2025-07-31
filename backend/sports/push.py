import os
import logging

try:
    from firebase_admin import messaging, credentials, initialize_app
except Exception:  # pragma: no cover - optional dep
    messaging = None
    credentials = None
    initialize_app = None

logger = logging.getLogger(__name__)

FCM_ENABLED = os.getenv("FCM_ENABLED", "False") == "True" or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
_initialized = False

def _ensure_init():
    global _initialized
    if not FCM_ENABLED or messaging is None:
        return False
    if not _initialized:
        try:
            initialize_app()
            _initialized = True
        except Exception:  # pragma: no cover
            logger.warning("FCM initialization failed", exc_info=True)
            return False
    return True

def push_to_user(user, title, body, data=None):
    if not _ensure_init():
        return False
    tokens = list(user.devices.filter(is_active=True).values_list("token", flat=True))
    if not tokens:
        return False
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        tokens=tokens,
    )
    try:
        messaging.send_multicast(message)
        return True
    except Exception:  # pragma: no cover
        logger.warning("FCM push failed", exc_info=True)
        return False
