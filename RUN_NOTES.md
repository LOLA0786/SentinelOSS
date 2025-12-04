ALLALL++ safe upgrade applied.

Omitted (refused) components:
 - exploit generation / automation
 - synthetic malware generator
 - automated adversarial prompt attack generator

These are refused for safety; use simulation stubs instead.

Safe commands:
 - start api: uvicorn senoss_core.api.extended_server_full:app --host 0.0.0.0 --port 8000
 - run demo sim: python3 demos/safe_redteam_sim.py
