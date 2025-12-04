from fastapi import FastAPI, Header, HTTPException
from senoss_core.auth.jwt_auth import create_token, verify_token, has_role
from senoss_core.workflows.engine import WorkflowEngine
from senoss_core.agents.auto.loop import AutonomousDefender
from senoss_core.agents.runtime import AgentRuntime

app = FastAPI(title="senoss extended API")
workflow = WorkflowEngine()
autodef = AutonomousDefender(interval=3)
agent = AgentRuntime()

@app.post("/auth/token")
def token(username: str):
    # naive: grant 'admin' to 'admin', else 'user'
    roles = ["admin"] if username == "admin" else ["user"]
    return {"access_token": create_token(username, roles)}

@app.post("/workflow/run")
def run_workflow(payload: dict, authorization: str = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="missing token")
    token = authorization.split()[-1]
    payload_token = verify_token(token)
    if not payload_token:
        raise HTTPException(status_code=401, detail="invalid token")
    # simple workflow: add a step that calls agent.run
    def step_call_agent(ctx):
        agent.run({"workflow": ctx})
        return {"status": "agent-called", "original": ctx}
    workflow.add_step(step_call_agent)
    res = workflow.run(payload)
    return res

@app.post("/autodef/start")
def start_autodef(authorization: str = Header(None)):
    token = None
    if authorization:
        token = authorization.split()[-1]
    payload_token = verify_token(token) if token else None
    if not payload_token or not has_role(payload_token, "admin"):
        raise HTTPException(status_code=403, detail="admin role required")
    autodef.start()
    return {"status": "autodef started"}
