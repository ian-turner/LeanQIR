# LeanQIR Knowledge Base

Formalizing the semantics of [QIR](https://github.com/qir-alliance/qir-spec) (Quantum Intermediate Representation) in Lean 4, with simulation-based verification.

## Pages

- [Project Overview](project-overview.md) — goals, structure, current status
- [QIR Primer](qir-primer.md) — what QIR is, profiles, instruction set
- [QIR Example Fixtures](qir-example-fixtures.md) — profile/version assumptions for `examples/*.ll`
- [Lean Formalization](lean-formalization.md) — the Lean 4 project layout and plans
- [Simulation & Verification](simulation.md) — using MQT DDSIM and qir-runner to verify semantics

## Quick Reference

| Thing | Where |
|---|---|
| Lean source | `lean/LeanQIR/` |
| Example circuits | `examples/*.ll` |
| Simulation script | `scripts/simulate.py` |
| Python environment | `quantum` conda env |
