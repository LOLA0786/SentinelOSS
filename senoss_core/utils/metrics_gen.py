import random, time, threading

class MetricsGenerator:
    def __init__(self, cb, interval=2):
        self.cb = cb
        self.interval = interval
        self._stop = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True)

    def start(self):
        self.thread.start()

    def stop(self):
        self._stop.set()
        self.thread.join(timeout=2)

    def _run(self):
        while not self._stop.is_set():
            metrics = {
                "cpu": random.randint(1, 100),
                "requests": random.randint(0, 10000)
            }
            try:
                self.cb(metrics)
            except Exception:
                pass
            time.sleep(self.interval)
