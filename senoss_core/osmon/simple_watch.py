import psutil, time, threading, os
from typing import Callable

class SimpleOSMonitor:
    def __init__(self, cb: Callable[[dict], None], interval: float = 2.0):
        self.cb = cb
        self.interval = interval
        self._stop = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True)

    def start(self):
        if not self.thread.is_alive():
            self.thread.start()

    def stop(self):
        self._stop.set()
        self.thread.join(timeout=2)

    def _run(self):
        while not self._stop.is_set():
            try:
                metrics = {
                    "cpu_percent": psutil.cpu_percent(interval=None),
                    "mem_percent": psutil.virtual_memory().percent,
                    "process_count": len(psutil.pids()),
                }
                self.cb(metrics)
            except Exception:
                pass
            time.sleep(self.interval)
