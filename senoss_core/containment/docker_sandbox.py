import subprocess, shlex, uuid

def run_safe_container(cmd):
    cid = "safe-" + uuid.uuid4().hex[:6]
    run = f"docker run --rm --name {cid} --network none alpine:3.18 sh -c {shlex.quote(cmd)}"
    try:
        p = subprocess.run(run, shell=True, capture_output=True, text=True, timeout=10)
        return {"code": p.returncode, "out": p.stdout, "err": p.stderr}
    except Exception as e:
        return {"error": str(e)}
