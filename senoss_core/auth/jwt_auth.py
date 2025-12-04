from datetime import datetime, timedelta
from jose import jwt, JWTError

SECRET = "change-me-please"
ALGO = "HS256"
ACCESS_EXPIRES_MINUTES = 60

def create_token(subject: str, roles: list):
    to_encode = {"sub": subject, "roles": roles, "exp": datetime.utcnow() + timedelta(minutes=ACCESS_EXPIRES_MINUTES)}
    return jwt.encode(to_encode, SECRET, algorithm=ALGO)

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET, algorithms=[ALGO])
        return payload
    except JWTError:
        return None

def has_role(token_payload: dict, role: str):
    roles = token_payload.get("roles", []) if token_payload else []
    return role in roles
