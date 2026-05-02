# Lean Formalization

## Project Setup

- **Build tool:** Lake (Lean's package manager)
- **Config:** `lean/lakefile.toml`
- **Toolchain:** see `lean/lean-toolchain`
- **Entry point:** `lean/LeanQIR.lean` imports `LeanQIR.Basic`

Build with:
```bash
cd lean && lake build
```

## Current State

`LeanQIR/Basic.lean` is a placeholder (`def hello := "world"`). The formalization has not started yet.

## Planned Structure

The formalization will likely grow into multiple files under `lean/LeanQIR/`:

| File (planned) | Content |
|---|---|
| `Syntax.lean` | Inductive types for QIR instructions and programs |
| `State.lean` | Quantum state representation (statevectors / density matrices) |
| `Semantics.lean` | Operational semantics (small-step or big-step) |
| `Denotational.lean` | Denotational semantics via superoperators |
| `Equiv.lean` | Equivalence proofs between semantic styles |

## Design Decisions (TBD)

- **Scope of LLVM modeling:** The spec embeds QIR inside LLVM SSA. We can either
  model full SSA (variables, phi-nodes, basic blocks with names) or abstract to
  a QIR-specific IR that elides SSA bookkeeping. Starting with an abstraction is
  simpler; SSA can be added later.
- **Qubit/result representation:** In the Base Profile, qubits are just `Nat`
  indices. The Lean `Syntax.lean` can define `Qubit := Fin n` (bounded) or plain
  `Nat`. Results are similarly indexed.
- **QIS gate set:** The spec does not mandate specific gates. For the formalization
  we will pick a concrete finite gate set (H, X, Y, Z, S, T, CNOT, CZ, Rx, Ry, Rz,
  Mz, Reset) sufficient to cover our example circuits, and model everything else
  as opaque.
- **Matrix library:** Lean's Mathlib has `Matrix` over `ℂ`. A complex 2ⁿ×2ⁿ
  matrix suffices for state-vector semantics. Density matrices need `Matrix (Fin (2^n)) (Fin (2^n)) ℂ`.
- **Adaptive Profile control flow:** Classical `i1` variables and conditional `br`
  mean the formalization needs a CFG (control-flow graph) or a structured
  control-flow representation. For the Base Profile, the four-block linear
  structure is much simpler to formalize first.
- **Profile stratification:** Plan to formalize Base Profile first, then extend
  to Adaptive. Many semantic rules are shared; the Adaptive Profile adds a
  `read_result → i1` operation and conditional branching.
