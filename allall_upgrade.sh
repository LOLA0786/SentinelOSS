set -euo pipefail

# working dir check
ROOT=$(pwd)
echo "Applying ALLALL++ safe upgrades in $ROOT"

# ---------------------------
# 0. create directories
# ---------------------------
mkdir -p senoss_core/soar
mkdir -p senoss_core/osmon
mkdir -p senoss_core/modelguard
mkdir -p senoss_core/agents/supervisor
mkdir -p senoss_core/intel/yara
mkdir -p senoss_core/cloud
mkdir -p senoss_core/identity
mkdir -p senoss_core/containment
mkdir -p webui
mkdir -p infra
mkdir -p demos

# ---------------------------
# 1. SOAR: playbooks + action adapters
# ---------------------------
cat > senoss_core/soar/playbook.py <<'PY'
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
PY

cat > senoss_core/soar/__init__.py <<'PY'
from .playbook import Playbook, PlaybookStep, action_block_ip, action_create_ticket
PY

# ---------------------------
# 2. OS Monitor (user-space, cross-platform safe monitors)
# ---------------------------
cat > senoss_core/osmon/simple_watch.py <<'PY'
import psutil, time, threading, os
from typing import Callable

class SimpleOSMonitor:
    def __init__(self, cb: Callable[[dict], None], interval: float = 2.0):
        self.cb = cb
        self.interval = interval
        self._stop = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True)

    def start(self):
        if not self.thread.is_alive():
            self.thread.start()

    def stop(self):
        self._stop.set()
        self.thread.join(timeout=2)

    def _run(self):
        while not self._stop.is_set():
            try:
                metrics = {
                    "cpu_percent": psutil.cpu_percent(interval=None),
                    "mem_percent": psutil.virtual_memory().percent,
                    "process_count": len(psutil.pids()),
                }
                self.cb(metrics)
            except Exception:
                pass
            time.sleep(self.interval)
PY

cat > senoss_core/osmon/__init__.py <<'PY'
from .simple_watch import SimpleOSMonitor
PY

# ---------------------------
# 3. Model Guard (LLM I/O filtering, jailbreak heuristics, rate-limits)
# ---------------------------
cat > senoss_core/modelguard/filtering.py <<'PY'
from typing import Dict, Optional
import time, hashlib

# Simple in-memory rate limiter & heuristics
class ModelGuard:
    def __init__(self):
        self.recent = {}
        self.blocked_patterns = ["bypass safety", "ignore instructions", "password", "crack", "exploit"]

    def check_input(self, prompt: str, client_id: Optional[str]=None):
        key = (client_id or "anon") + "|" + hashlib.sha256(prompt.encode()).hexdigest()[:8]
        now = time.time()
        self.recent.setdefault(key, now)
        # heuristic matching
        low = prompt.lower()
        for p in self.blocked_patterns:
            if p in low:
                return {"allow": False, "reason": "policy-match"}
        return {"allow": True}

    def check_output(self, text: str):
        # ensure outputs do not contain sensitive patterns
        for p in ["ssh ", "eval(", "os.system", "rm -rf"]:
            if p in text:
                return {"safe": False, "reason": "unsafe-output"}
        return {"safe": True}
PY

cat > senoss_core/modelguard/__init__.py <<'PY'
from .filtering import ModelGuard
PY

# ---------------------------
# 4. Supervisor Agent / Multi-Agent runtime (safe orchestration)
# ---------------------------
cat > senoss_core/agents/supervisor/supervisor.py <<'PY'
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
PY

cat > senoss_core/agents/supervisor/__init__.py <<'PY'
from .supervisor import SupervisorAgent
PY

# ---------------------------
# 5. YARA stub integration & advanced intel helpers
# ---------------------------
cat > senoss_core/intel/yara/loader.py <<'PY'
# This is a safe YARA rule loader stub.
# Real YARA scanning requires 'yara' package and user-supplied rules. We do not ship malicious rules.
from pathlib import Path
import json

RULE_DIR = Path("senoss_core/intel/yara/rules")
RULE_DIR.mkdir(parents=True, exist_ok=True)

def list_rules():
    return [p.name for p in RULE_DIR.glob("*.yara")]

def add_placeholder_rule(name: str, content: str):
    p = RULE_DIR / (name + ".yara")
    p.write_text(content)
    return p.as_posix()

def load_rules():
    return list_rules()
PY

cat > senoss_core/intel/yara/__init__.py <<'PY'
from .loader import list_rules, add_placeholder_rule, load_rules
PY

# ---------------------------
# 6. Cloud connectors (read-only checks: AWS S3 list buckets, GCP/Azure stubs)
# ---------------------------
cat > senoss_core/cloud/aws_audit.py <<'PY'
# Safe, read-only AWS checks. Requires AWS credentials if used.
import boto3, botocore

def list_s3_buckets():
    try:
        s3 = boto3.client("s3")
        resp = s3.list_buckets()
        return {"buckets": [b["Name"] for b in resp.get("Buckets", [])]}
    except botocore.exceptions.NoCredentialsError:
        return {"error": "no-aws-creds"}
    except Exception as e:
        return {"error": str(e)}
PY

cat > senoss_core/cloud/__init__.py <<'PY'
from .aws_audit import list_s3_buckets
PY

# ---------------------------
# 7. Identity & Access Layer (behavioral risk scoring)
# ---------------------------
cat > senoss_core/identity/risk.py <<'PY'
import time, hashlib

class IdentityRiskEngine:
    def __init__(self):
        self.sessions = {}

    def score_event(self, user_id: str, event: dict):
        # naive behavioral score
        key = user_id
        base = 50
        if event.get("unusual_location"): base += 25
        if event.get("suspicious_cmd"): base += 30
        if event.get("fast_activity"): base += 15
        return {"user": user_id, "risk_score": min(100, base), "ts": time.time()}
PY

cat > senoss_core/identity/__init__.py <<'PY'
from .risk import IdentityRiskEngine
PY

# ---------------------------
# 8. Containment sandbox improvements (enhanced docker runner + logging)
# ---------------------------
cat > senoss_core/containment/docker_sandbox.py <<'PY'
import subprocess, shlex, uuid, time, json
from typing import Dict

def run_safe_container(cmd: str, timeout: int = 10):
    # non-privileged ephemeral container; network disabled
    cid = "senoss-sbox-" + uuid.uuid4().hex[:8]
    full = f"docker run --rm --name {cid} --network none --pids-limit 64 --cpus=0.5 --memory=256m alpine:3.18 sh -c {shlex.quote(cmd)}"
    try:
        p = subprocess.run(full, shell=True, capture_output=True, text=True, timeout=timeout)
        return {"exit_code": p.returncode, "stdout": p.stdout, "stderr": p.stderr}
    except subprocess.TimeoutExpired:
        return {"exit_code": -1, "stderr": "timeout"}
PY

cat > senoss_core/containment/__init__.py <<'PY'
from .docker_sandbox import run_safe_container
PY

# ---------------------------
# 9. Security Copilot UI (simple React placeholder + static server)
# ---------------------------
cat > webui/package.json <<'JSON'
{
  "name": "senoss-webui",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "serve -s build -l 3000",
    "build": "echo 'placeholder build' > build/index.html"
  },
  "dependencies": {}
}
JSON

cat > webui/README.md <<'MD'
Simple placeholder web UI. Run in root: (requires node/npm if you want to expand)
  cd webui
  npm install -g serve
  npm run build
  npm start
MD

# ---------------------------
# 10. Demos: safe red-team simulation (NO exploit code)
# ---------------------------
cat > demos/safe_redteam_sim.py <<'PY'
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
PY

# ---------------------------
# 11. Infra helpers: dockerfile + compose ensure
# ---------------------------
cat > infra/Dockerfile.api <<'DOCK'
FROM python:3.11-slim
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["uvicorn", "senoss_core.api.extended_server_full:app", "--host", "0.0.0.0", "--port", "8000"]
DOCK

cat > infra/docker-compose.override.yml <<'YML'
version: "3.9"
services:
  api:
    build:
      context: ..
      dockerfile: infra/Dockerfile.api
    ports:
      - "8000:8000"
YML

# ---------------------------
# 12. Update requirements
# ---------------------------
cat > requirements.txt <<'REQ'
fastapi
uvicorn
python-jose
streamlit
pytest
sqlalchemy
python-dotenv
python-multipart
python-jose
python-dateutil
requests
psutil
boto3
serve
PyYAML
REQ

# ---------------------------
# 13. Lightweight docs and run helpers
# ---------------------------
cat > RUN_NOTES.md <<'MD'
ALLALL++ safe upgrade applied.

Omitted (refused) components:
 - exploit generation / automation
 - synthetic malware generator
 - automated adversarial prompt attack generator

These are refused for safety; use simulation stubs instead.

Safe commands:
 - start api: uvicorn senoss_core.api.extended_server_full:app --host 0.0.0.0 --port 8000
 - run demo sim: python3 demos/safe_redteam_sim.py
MD

# ---------------------------
# 14. Tests additions
# ---------------------------
cat > tests/test_soar.py <<'PY'
from senoss_core.soar import Playbook, PlaybookStep, action_block_ip
def test_playbook():
    pb = Playbook("p")
    pb.add_step(PlaybookStep("s1", lambda ctx: {"a":1}))
    res = pb.run({"incident_id":"42"})
    assert "results" in res
PY

# ---------------------------
# 15. Git commit & push
# ---------------------------
git add -A
git commit -m "ALLALL++ safe: SOAR, OS monitor, model guard, supervisor, YARA stubs, cloud connectors, identity, containment, copilot UI stub, safe red-team sim"
git push

echo "SAFE ALLALL++ applied. Refused exploit/malware features. Use simulations instead."
set -euo pipefail

ROOT=$(pwd)
echo "Running ALLALL++ safe upgrade in $ROOT"

# ---------- (SCRIPT CONTENT WILL BE INSERTED BELOW AUTOMATICALLY) ----------

