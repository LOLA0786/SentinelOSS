class BehaviorFirewall:
    def __init__(self):
        self.blocklist = ["rm -rf", "hack", "bruteforce"]

    def inspect(self, text: str):
        for b in self.blocklist:
            if b in text.lower():
                return False
        return True
