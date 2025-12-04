import time

class IdentityRiskEngine:
    def score(self, user, event):
        score = 50
        if event.get("unusual_location"): score += 25
        if event.get("fast_activity"): score += 10
        if event.get("suspicious_cmd"): score += 15
        return {"user": user, "risk": min(score,100), "ts": time.time()}
