import uuid, time, asyncio
from senoss_core.graph import get_bus

class SupervisorAgent:
    def __init__(self):
        self.id = "supervisor-" + uuid.uuid4().hex[:6]
        self.bus = get_bus()

    async def handle(self, msg):
        t = msg.get("type")
        if t == "ioc_match":
            await self.bus.publish("alerts", {"alert": msg})
        await self.bus.publish("heartbeat", {"agent": self.id, "ts": time.time()})
