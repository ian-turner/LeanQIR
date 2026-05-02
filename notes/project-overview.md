# Project Overview

## Goal

Build a formal semantics for QIR (Quantum Intermediate Representation) in Lean 4, then prove properties about it. Use classical simulation as a ground truth to validate that the semantic rules are correct before attempting proofs.

## Current Status

The Lean project builds with a first-pass circuit semantics, a QIR-facing Base
Profile structure layer, and a Lean-native Base emitter. The simulation harness
is working: checked-in Bell/teleportation fixtures run, and the Lean-emitted
Bell program runs through `scripts/simulate.py`.

## Repository Layout

```
examples/           QIR circuit files (.ll) used for testing
  bell.ll           Bell state: H + CNOT, measures 2 qubits
  teleportation.ll  Quantum teleportation (adaptive profile, classical control)
lean/               Lean 4 project (Lake)
  lakefile.toml
  lean-toolchain
  LeanQIR.lean      Core root import
  LeanQIR/
    Syntax.lean     Circuit-level syntax
    State.lean      Statevector operations
    Semantics.lean  Big-step statevector semantics
    Examples.lean   Examples root import, separate from the core library target
    Examples/
      Bell.lean      Bell fixture, well-formedness proof, and emitter CLI main
    QIR/
      Base.lean     QIR Base Profile structure and well-formedness
      Emit.lean     BaseProgram-to-LLVM-text emitter
scripts/
  simulate.py       Run a .ll file with qir-runner, print outcome counts
notes/              This wiki
```

## Planned Work

### Phase 1 — Base Profile formalization
1. Define QIR types in Lean: `Qubit`, `Result`, `Gate`, `Instr`, `Program`
   (see `lean-formalization.md` for module layout)
2. Model the Base Profile's four-block program structure as a Lean record
   (initial version done in `LeanQIR.QIR.Base`)
3. Emit structured Base programs back to `.ll` for simulator cross-checks
   (initial Bell path done via the separate `LeanQIR.Examples` module and
   `lake exe emit_bell`)
4. Define an operational semantics over statevectors (big-step, Base Profile only)
5. Cross-check rules against MQT DDSIM simulation output

### Phase 2 — Denotational semantics
6. Define density-matrix semantics using Mathlib `Matrix ℂ`
7. Prove equivalence between operational and denotational for Base Profile

### Phase 3 — Adaptive Profile
8. Extend syntax with `i1` classical variables, conditional `br`, and a CFG
9. Extend semantics with `read_result`, conditional execution
10. Prove key correctness properties (e.g. teleportation correctness)

### Key spec facts to encode
- Qubits are `Fin numQubits` (static allocation) or opaque ptrs (dynamic)
- Results are write-once; only `result_record_output` may read them
- Measurement functions are marked `irreversible`; qubits cannot be reused
  after measurement in Base Profile
- Module flags control which capabilities are active
