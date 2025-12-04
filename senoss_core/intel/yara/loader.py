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
