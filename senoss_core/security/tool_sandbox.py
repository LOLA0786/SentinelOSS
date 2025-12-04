import subprocess

class ToolSandbox:
    def run(self, cmd):
        safe = ["echo", "ls", "pwd"]
        if cmd.split()[0] not in safe:
            return {"error": "blocked"}
        out = subprocess.getoutput(cmd)
        return {"output": out}
