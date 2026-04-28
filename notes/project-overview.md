# Project Overview

## Goal

Build a formal semantics for QIR (Quantum Intermediate Representation) in Lean 4, then prove properties about it. Use classical simulation as a ground truth to validate that the semantic rules are correct before attempting proofs.

## Current Status

Early scaffolding. The Lean project builds but `LeanQIR/Basic.lean` is a placeholder. The simulation harness is working (Bell state and teleportation circuits run successfully via `scripts/simulate.py`).

## Repository Layout

```
examples/           QIR circuit files (.ll) used for testing
  bell.ll           Bell state: H + CNOT, measures 2 qubits
  teleportation.ll  Quantum teleportation (adaptive profile, classical control)
lean/               Lean 4 project (Lake)
  lakefile.toml
  lean-toolchain
  LeanQIR.lean      Root import
  LeanQIR/
    Basic.lean      Placeholder — formalization goes here
scripts/
  simulate.py       Run a .ll file with qir-runner, print outcome counts
notes/              This wiki
```

## Planned Work

1. Define QIR types and instructions as Lean 4 inductive types
2. Define a small-step or big-step operational semantics
3. Define a denotational semantics (density matrices)
4. Prove equivalence between operational and denotational semantics
5. Use simulation results (MQT DDSIM) to cross-check semantic rules during development
