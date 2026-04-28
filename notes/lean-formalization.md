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

- Whether to model the full LLVM SSA structure or a simplified QIR-specific IR
- Whether to use complex matrices from Mathlib or define a lightweight matrix type
- How to handle the Adaptive Profile's classical control flow in the Lean model
