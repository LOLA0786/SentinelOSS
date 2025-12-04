import asyncio, random, time
from senoss_core.threatintel import load_iocs
from senoss_core.events import publish_event

async def run_sim(rounds=5):
    iocs = load_iocs()
    for _ in range(rounds):
        pick = random.choice(iocs)
        await publish_event({"type":"simulated_ioc","ioc":pick,"ts":time.time()})
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(run_sim())
