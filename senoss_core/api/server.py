from fastapi import FastAPI
from senoss_core.agents.runtime import AgentRuntime
from senoss_core.security.anomaly_detector import AnomalyDetector

app = FastAPI()
agent = AgentRuntime()
anomaly = AnomalyDetector()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/agent/run")
def run_agent(payload: dict):
    return agent.run(payload)

@app.post("/anomaly/check")
def anomaly_check(metrics: dict):
    return {"anomaly": anomaly.detect(metrics)}
