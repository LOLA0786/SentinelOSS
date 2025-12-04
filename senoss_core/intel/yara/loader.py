from pathlib import Path

RULE_DIR = Path("senoss_core/intel/yara/rules")
RULE_DIR.mkdir(parents=True, exist_ok=True)

def list_rules():
    return [p.name for p in RULE_DIR.glob("*.yara")]

def add_rule(name, body):
    fp = RULE_DIR / f"{name}.yara"
    fp.write_text(body)
    return fp.as_posix()
