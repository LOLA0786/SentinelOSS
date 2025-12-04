from typing import List, Callable

class WorkflowEngine:
    def __init__(self):
        self.steps = []

    def add_step(self, fn: Callable):
        self.steps.append(fn)

    def run(self, payload: dict):
        ctx = payload
        for step in self.steps:
            ctx = step(ctx) or ctx
        return ctx
