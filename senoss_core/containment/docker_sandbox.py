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
