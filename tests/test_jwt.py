from senoss_core.auth.jwt_auth import create_token, verify_token, has_role
def test_jwt_roundtrip():
    t = create_token("u", ["user"])
    p = verify_token(t)
    assert p and p.get("sub") == "u"
    assert has_role(p, "user")
