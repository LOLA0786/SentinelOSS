import uuid

class AgentRuntime:
    def __init__(self):
        self.id = str(uuid.uuid4())

    def run(self, payload: dict):
        return {
            "agent_id": self.id,
            "status": "ok",
            "input": payload,
        }
