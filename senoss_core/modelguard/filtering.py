from typing import Dict, Optional
import time, hashlib

# Simple in-memory rate limiter & heuristics
class ModelGuard:
    def __init__(self):
        self.recent = {}
        self.blocked_patterns = ["bypass safety", "ignore instructions", "password", "crack", "exploit"]

    def check_input(self, prompt: str, client_id: Optional[str]=None):
        key = (client_id or "anon") + "|" + hashlib.sha256(prompt.encode()).hexdigest()[:8]
        now = time.time()
        self.recent.setdefault(key, now)
        # heuristic matching
        low = prompt.lower()
        for p in self.blocked_patterns:
            if p in low:
                return {"allow": False, "reason": "policy-match"}
        return {"allow": True}

    def check_output(self, text: str):
        # ensure outputs do not contain sensitive patterns
        for p in ["ssh ", "eval(", "os.system", "rm -rf"]:
            if p in text:
                return {"safe": False, "reason": "unsafe-output"}
        return {"safe": True}
