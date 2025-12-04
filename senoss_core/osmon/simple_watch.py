import psutil, time, threading

class SimpleOSMonitor:
    def __init__(self, cb, interval=2):
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
                data = {
                    "cpu": psutil.cpu_percent(),
                    "mem": psutil.virtual_memory().percent,
                    "procs": len(psutil.pids()),
                }
                self.cb(data)
            except:
                pass
            time.sleep(self.interval)
