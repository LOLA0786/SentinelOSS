class ModelGuard:
    def __init__(self):
        self.bad_patterns = ["bypass", "ignore safety", "exploit", "crack"]

    def check_input(self, text):
        low = text.lower()
        for p in self.bad_patterns:
            if p in low:
                return {"allow": False, "reason": "blocked-pattern"}
        return {"allow": True}

    def check_output(self, text):
        for p in ["rm -rf", "ssh ", "eval("]:
            if p in text:
                return {"safe": False, "reason": "unsafe-output"}
        return {"safe": True}
