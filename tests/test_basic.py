from senoss_core.agents.runtime import AgentRuntime

def test_agent():
    a = AgentRuntime()
    assert "agent_id" in a.run({"x":1})
