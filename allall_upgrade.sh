# ============================================
# SAFE ALLALL++ UPGRADE SCRIPT
# ============================================

ROOT=$(pwd)
echo "Applying ALLALL++ safe upgrades in $ROOT"

# ---------------------------
# CREATE DIRECTORIES
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
# 1. SOAR PLAYBOOK ENGINE
# ---------------------------
cat > senoss_core/soar/playbook.py << 'EOF2'
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
EOF2

cat > senoss_core/soar/__init__.py << 'EOF2'
from .playbook import Playbook, PlaybookStep, action_block_ip, action_create_ticket
EOF2


# ---------------------------
# 2. OS MONITOR
# ---------------------------
cat > senoss_core/osmon/simple_watch.py << 'EOF2'
import psutil, time, threading

class SimpleOSMonitor:
    def __init__(self, cb, interval=2):
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
                data = {
                    "cpu": psutil.cpu_percent(),
                    "mem": psutil.virtual_memory().percent,
                    "procs": len(psutil.pids()),
                }
                self.cb(data)
            except:
                pass
            time.sleep(self.interval)
EOF2

cat > senoss_core/osmon/__init__.py << 'EOF2'
from .simple_watch import SimpleOSMonitor
EOF2


# ---------------------------
# 3. MODEL GUARD
# ---------------------------
cat > senoss_core/modelguard/filtering.py << 'EOF2'
class ModelGuard:
    def __init__(self):
        self.bad_patterns = ["bypass", "ignore safety", "exploit", "crack"]

    def check_input(self, text):
        low = text.lower()
        for p in self.bad_patterns:
            if p in low:
                return {"allow": False, "reason": "blocked-pattern"}
        return {"allow": True}

    def check_output(self, text):
        for p in ["rm -rf", "ssh ", "eval("]:
            if p in text:
                return {"safe": False, "reason": "unsafe-output"}
        return {"safe": True}
EOF2

cat > senoss_core/modelguard/__init__.py << 'EOF2'
from .filtering import ModelGuard
EOF2


# ---------------------------
# 4. SUPERVISOR AGENT
# ---------------------------
cat > senoss_core/agents/supervisor/supervisor.py << 'EOF2'
import uuid, time, asyncio
from senoss_core.graph import get_bus

class SupervisorAgent:
    def __init__(self):
        self.id = "supervisor-" + uuid.uuid4().hex[:6]
        self.bus = get_bus()

    async def handle(self, msg):
        t = msg.get("type")
        if t == "ioc_match":
            await self.bus.publish("alerts", {"alert": msg})
        await self.bus.publish("heartbeat", {"agent": self.id, "ts": time.time()})
EOF2

cat > senoss_core/agents/supervisor/__init__.py << 'EOF2'
from .supervisor import SupervisorAgent
EOF2


# ---------------------------
# 5. YARA SAFE STUBS
# ---------------------------
cat > senoss_core/intel/yara/loader.py << 'EOF2'
from pathlib import Path

RULE_DIR = Path("senoss_core/intel/yara/rules")
RULE_DIR.mkdir(parents=True, exist_ok=True)

def list_rules():
    return [p.name for p in RULE_DIR.glob("*.yara")]

def add_rule(name, body):
    fp = RULE_DIR / f"{name}.yara"
    fp.write_text(body)
    return fp.as_posix()
EOF2

cat > senoss_core/intel/yara/__init__.py << 'EOF2'
from .loader import list_rules, add_rule
EOF2


# ---------------------------
# 6. CLOUD CONNECTOR (READ ONLY)
# ---------------------------
cat > senoss_core/cloud/aws_audit.py << 'EOF2'
import boto3, botocore

def list_s3_buckets():
    try:
        cli = boto3.client("s3")
        r = cli.list_buckets()
        return {"buckets": [b["Name"] for b in r.get("Buckets",[])]}
    except botocore.exceptions.NoCredentialsError:
        return {"error": "no-aws-creds"}
    except Exception as e:
        return {"error": str(e)}
EOF2

cat > senoss_core/cloud/__init__.py << 'EOF2'
from .aws_audit import list_s3_buckets
EOF2


# ---------------------------
# 7. IDENTITY RISK ENGINE
# ---------------------------
cat > senoss_core/identity/risk.py << 'EOF2'
import time

class IdentityRiskEngine:
    def score(self, user, event):
        score = 50
        if event.get("unusual_location"): score += 25
        if event.get("fast_activity"): score += 10
        if event.get("suspicious_cmd"): score += 15
        return {"user": user, "risk": min(score,100), "ts": time.time()}
EOF2

cat > senoss_core/identity/__init__.py << 'EOF2'
from .risk import IdentityRiskEngine
EOF2


# ---------------------------
# 8. CONTAINMENT SANDBOX
# ---------------------------
cat > senoss_core/containment/docker_sandbox.py << 'EOF2'
import subprocess, shlex, uuid

def run_safe_container(cmd):
    cid = "safe-" + uuid.uuid4().hex[:6]
    run = f"docker run --rm --name {cid} --network none alpine:3.18 sh -c {shlex.quote(cmd)}"
    try:
        p = subprocess.run(run, shell=True, capture_output=True, text=True, timeout=10)
        return {"code": p.returncode, "out": p.stdout, "err": p.stderr}
    except Exception as e:
        return {"error": str(e)}
EOF2

cat > senoss_core/containment/__init__.py << 'EOF2'
from .docker_sandbox import run_safe_container
EOF2


# ---------------------------
# 9. WEB UI PLACEHOLDER
# ---------------------------
cat > webui/index.html << 'EOF2'
<!doctype html>
<html>
  <body>
    <h2>senoss - Security Copilot</h2>
    <p>Placeholder UI loaded.</p>
  </body>
</html>
EOF2


# ---------------------------
# 10. SAFE REDTEAM SIM
# ---------------------------
cat > demos/safe_redteam_sim.py << 'EOF2'
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
EOF2


# ---------------------------
# UPDATE REQUIREMENTS
# ---------------------------
cat > requirements.txt << 'EOF2'
fastapi
uvicorn
python-jose
pytest
sqlalchemy
psutil
boto3
requests
EOF2


# ---------------------------
# GIT COMMIT + PUSH
# ---------------------------
git add -A
git commit -m "ALLALL++ safe expansion applied"
git push

echo "SAFE ALLALL++ UPGRADE COMPLETED"
set -euo pipefail
...
