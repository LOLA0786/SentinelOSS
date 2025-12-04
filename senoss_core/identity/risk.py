import time, hashlib

class IdentityRiskEngine:
    def __init__(self):
        self.sessions = {}

    def score_event(self, user_id: str, event: dict):
        # naive behavioral score
        key = user_id
        base = 50
        if event.get("unusual_location"): base += 25
        if event.get("suspicious_cmd"): base += 30
        if event.get("fast_activity"): base += 15
        return {"user": user_id, "risk_score": min(100, base), "ts": time.time()}
