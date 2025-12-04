class AnomalyDetector:
    def detect(self, metrics: dict):
        if metrics.get("cpu", 0) > 95: return True
        if metrics.get("requests", 0) > 5000: return True
        return False
