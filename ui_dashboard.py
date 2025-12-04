import streamlit as st
from senoss_core.utils.metrics_gen import MetricsGenerator
from senoss_core.agents.runtime import AgentRuntime
from senoss_core.security.anomaly_detector import AnomalyDetector

st.title("senoss Dashboard")
anomaly = AnomalyDetector()
agent = AgentRuntime()

metrics_placeholder = st.empty()
status = st.empty()

def on_metrics(m):
    metrics_placeholder.write(m)
    if anomaly.detect(m):
        status.warning("Anomaly detected! Running agent...")
        agent.run({"trigger": "anomaly", "metrics": m})
    else:
        status.info("All normal")

gen = MetricsGenerator(on_metrics, interval=2)
if st.button("Start Metrics"):
    gen.start()
if st.button("Stop Metrics"):
    gen.stop()
