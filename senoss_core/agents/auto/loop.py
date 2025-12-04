import threading
import time
from senoss_core.agents.runtime import AgentRuntime
from senoss_core.security.anomaly_detector import AnomalyDetector

class AutonomousDefender:
    def __init__(self, interval=5):
        self.interval = interval
        self.agent = AgentRuntime()
        self.anomaly = AnomalyDetector()
        self._stop = threading.Event()
        self.thread = threading.Thread(target=self._loop, daemon=True)

    def start(self):
        if not self.thread.is_alive():
            self.thread.start()

    def stop(self):
        self._stop.set()
        self.thread.join(timeout=2)

    def _loop(self):
        while not self._stop.is_set():
            # lightweight synthetic metrics
            metrics = {"cpu": 10, "requests": 1}
            if self.anomaly.detect(metrics):
                # on anomaly, run agent with context
                self.agent.run({"action": "investigate", "metrics": metrics})
            time.sleep(self.interval)
