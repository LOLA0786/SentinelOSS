from senoss_core.soar import Playbook, PlaybookStep, action_block_ip
def test_playbook():
    pb = Playbook("p")
    pb.add_step(PlaybookStep("s1", lambda ctx: {"a":1}))
    res = pb.run({"incident_id":"42"})
    assert "results" in res
