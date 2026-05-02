# LeanQIR Knowledge Base

Formalizing the semantics of [QIR](https://github.com/qir-alliance/qir-spec) (Quantum Intermediate Representation) in Lean 4, with simulation-based verification.

## Pages

- [Project Overview](project-overview.md) — goals, structure, current status
- [QIR Primer](qir-primer.md) — what QIR is, profiles, instruction set
- [QIR Example Fixtures](qir-example-fixtures.md) — profile/version assumptions for `examples/*.ll`
- [QIR Base Structure](qir-base-structure.md) — Lean representation of Base Profile entry-point structure
- [QIR Base Emitter](qir-emitter.md) — emitting structured Base programs to `.ll`
- [QIR Evaluation Plan](qir-evaluation-plan.md) — plan for executable floating-point probability evaluation
- [Program Block Refactor](program-block-refactor.md) — shared body/measurement structure for root and QIR programs
- [Lean Formalization](lean-formalization.md) — the Lean 4 project layout and plans
- [Simulation & Verification](simulation.md) — using MQT DDSIM and qir-runner to verify semantics

## Quick Reference

| Thing | Where |
|---|---|
| Lean source | `lean/LeanQIR/`, `lean/Examples/` |
| Examples module | `cd lean && lake build Examples` |
| Example circuits | `examples/*.ll` |
| Bell emitter CLI | `cd lean && lake exe emit_bell` |
| Simulation script | `scripts/simulate.py` |
| Python environment | `quantum` conda env |
