from senoss_core.agents.auto.loop import AutonomousDefender
def test_autodef_start_stop():
    ad = AutonomousDefender(interval=1)
    ad.start()
    ad.stop()
    assert True
