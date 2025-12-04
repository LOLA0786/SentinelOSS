# Safe red-team simulation: generates synthetic IOCs and sequences for testing defensive playbooks.
import asyncio, random, time
from senoss_core.threatintel import load_iocs
from senoss_core.graph import get_bus
from senoss_core.events import publish_event

async def run_demo(rounds=5, interval=1):
    bus = get_bus()
    iocs = load_iocs()
    for i in range(rounds):
        pick = random.choice(iocs)
        evt = {"type":"simulated_ioc","ioc": pick, "ts": time.time()}
        # publish via bus -> will be picked up by supervisor or UI
        await publish_event(evt)
        await asyncio.sleep(interval)

if __name__ == "__main__":
    asyncio.run(run_demo())
