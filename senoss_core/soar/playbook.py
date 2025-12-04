from typing import Dict, Callable, List

class PlaybookStep:
    def __init__(self, name: str, action: Callable[[Dict], Dict]):
        self.name = name
        self.action = action

class Playbook:
    def __init__(self, name: str):
        self.name = name
        self.steps: List[PlaybookStep] = []

    def add_step(self, step: PlaybookStep):
        self.steps.append(step)

    def run(self, context: Dict) -> Dict:
        ctx = context
        results = []
        for s in self.steps:
            try:
                res = s.action(ctx) or {}
                results.append({s.name: res})
                if isinstance(res, dict):
                    ctx.update(res)
            except Exception as e:
                results.append({s.name: {"error": str(e)}})
        return {"playbook": self.name, "results": results}

def action_block_ip(ctx):
    return {"blocked": ctx.get("ip")}

def action_create_ticket(ctx):
    return {"ticket": "T-" + ctx.get("incident_id", "0")}
