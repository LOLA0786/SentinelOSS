import uuid, asyncio, time
from senoss_core.graph import get_bus

class SupervisorAgent:
    def __init__(self):
        self.id = "supervisor-"+uuid.uuid4().hex[:6]
        self.bus = get_bus()

    async def handle(self, message):
        # simple policy: if event type is ioc_match, escalate
        t = message.get("type")
        if t == "ioc_match":
            await self.bus.publish("alerts", {"from": self.id, "alert": message})
        # record heartbeat
        await self.bus.publish("heartbeat", {"agent": self.id, "ts": time.time()})
