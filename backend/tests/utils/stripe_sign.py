import hmac
import hashlib
import time

def make_sig_header(payload_bytes: bytes, secret: str) -> str:
    ts = str(int(time.time()))
    mac = hmac.new(secret.encode(), (ts + '.' + payload_bytes.decode()).encode(), hashlib.sha256).hexdigest()
    return f"t={ts},v1={mac}"
