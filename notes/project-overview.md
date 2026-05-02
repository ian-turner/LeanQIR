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

### Phase 1 — Base Profile formalization
1. Define QIR types in Lean: `Qubit`, `Result`, `Gate`, `Instr`, `Program`
   (see `lean-formalization.md` for module layout)
2. Model the Base Profile's four-block program structure as a Lean record
3. Define an operational semantics over statevectors (big-step, Base Profile only)
4. Cross-check rules against MQT DDSIM simulation output

### Phase 2 — Denotational semantics
5. Define density-matrix semantics using Mathlib `Matrix ℂ`
6. Prove equivalence between operational and denotational for Base Profile

### Phase 3 — Adaptive Profile
7. Extend syntax with `i1` classical variables, conditional `br`, and a CFG
8. Extend semantics with `read_result`, conditional execution
9. Prove key correctness properties (e.g. teleportation correctness)

### Key spec facts to encode
- Qubits are `Fin numQubits` (static allocation) or opaque ptrs (dynamic)
- Results are write-once; only `result_record_output` may read them
- Measurement functions are marked `irreversible`; qubits cannot be reused
  after measurement in Base Profile
- Module flags control which capabilities are active
