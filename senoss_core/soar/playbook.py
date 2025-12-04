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
                ctx.update(res if isinstance(res, dict) else {})
            except Exception as e:
                results.append({s.name: {"error": str(e)}})
        return {"playbook": self.name, "results": results}
# sample actions (safe)
def action_block_ip(ctx):
    ip = ctx.get("ip")
    # NOTE: actual blocking (firewall calls) should be added by operator
    return {"blocked": ip}
def action_create_ticket(ctx):
    return {"ticket_id": "T-"+(ctx.get("incident_id","0"))}
