# Lean Formalization

## Project Setup

- **Build tool:** Lake (Lean's package manager)
- **Config:** `lean/lakefile.toml`
- **Toolchain:** see `lean/lean-toolchain`
- **Entry point:** `lean/LeanQIR.lean` imports `LeanQIR.Syntax`, `LeanQIR.State`, `LeanQIR.Semantics`
- **Dependency:** Mathlib (pinned via `lake-manifest.json`; resolve with `lake update`)

Build with:
```bash
cd lean && lake build
```

## Current State

Phase 1 first-pass code compiles. Three modules are implemented under `lean/LeanQIR/`:

| File | Status | Content |
|---|---|---|
| `Syntax.lean` | ✅ compiles | `Gate1`, `Gate1R`, `Gate2`, `GateInstr`, `MeasInstr`, `Program` |
| `State.lean` | ✅ compiles | `Statevector`, gate matrices, `getBit`, `setBit`, `applyGate1`, `applyGate2` |
| `Semantics.lean` | ✅ compiles | `BitString`, `measureQubit`, `evalGates`, `evalMeasurements`, `eval` |
| `Denotational.lean` | planned | Density-matrix semantics (Phase 2) |
| `Equiv.lean` | planned | Equivalence proofs (Phase 2) |

**Next steps:**
- Prove correctness of `setBit` round-trip: `getBit (setBit i k b) k = b`
- Write the Bell state circuit as a `Program 2 2` and verify `eval` returns the right probability distribution
- Cross-check `eval` output against `scripts/simulate.py` (qir-runner)
- Fill in any remaining `sorry`s (there are none currently; the `setBit` bound proof uses `nlinarith`)

## Design Decisions

### Settled

- **Semantics style:** Big-step for Base Profile. The four-block linear structure
  (entry → body → measurements → output) maps cleanly onto a big-step relation.
  Small-step would be needed for Adaptive Profile's CFG; defer until Phase 3.

- **LLVM modeling scope:** Abstract away SSA bookkeeping. Model QIR as a structured
  IR (list of gate calls, list of measurements, list of output calls) rather than
  full LLVM basic blocks with named SSA variables. SSA names are irrelevant to
  the semantics we care about for Base Profile.

- **Qubit/result representation:** `Qubit := Fin n` where `n` is the static qubit
  count declared in entry-point attributes. Results are `Fin m` similarly.
  Both are resolved at program elaboration time; no dynamic allocation in Phase 1.

- **QIS gate set:** Concrete finite set sufficient for our example circuits:
  `H, X, Y, Z, S, T, CNOT, CZ, Rx, Ry, Rz, Mz, Reset`. Everything else is opaque.

- **Statevector type:** `Fin (2^n) → ℂ` for Phase 1. This is the simplest
  computable representation. `EuclideanSpace ℂ (Fin (2^n))` is the Mathlib-preferred
  type for analysis/proofs and can be adopted in Phase 2.
  `n` is fixed at elaboration time (from `required_num_qubits`); it is not a
  runtime variable. This avoids the friction of `Fin (2^n)` with variable `n`
  (non-definitional type equalities, `#eval` not reducing, etc.).

- **Gate application:** Define `applyGate (k : Fin n) (G : Matrix (Fin 2) (Fin 2) ℂ)`
  directly via index arithmetic over `Fin (2^n)`, rather than via Kronecker products.
  Concretely, `(applyGate k G ψ) i = ∑ b, G[(i.val / 2^k) % 2, b] * ψ (i with bit k := b)`.
  This avoids the type mismatch from `Matrix.kronecker` producing `Fin 2 × Fin 2 × …`
  instead of `Fin (2^n)`, and keeps proofs tractable. The Kronecker product
  formulation is mathematically equivalent and can be used in Phase 2 proofs where needed.

- **Qubit index splitting for measurement:** To check whether qubit `k` of basis
  index `i : Fin (2^n)` is 0 or 1, use `(i.val / 2^k) % 2`. This is plain
  arithmetic; no special Mathlib equivalence needed. `finFunctionFinEquiv`
  (`Mathlib.Algebra.BigOperators.Fin`) is available if a bijection proof is needed.

- **Semantics return type (measurement):** The big-step relation returns a list of
  `(post-measurement statevector, outcome bitstring, probability)` triples — one
  per possible measurement outcome. This is richer than a bare probability
  distribution over bitstrings, and makes the Phase 3 extension to Adaptive Profile
  natural (post-measurement state feeds into subsequent classical control flow).
  Formally: `eval : Program → Statevector → List (Statevector × BitString × ℝ≥0)`.

- **Measurement probability:** For measuring qubit `k` in basis state `ψ : Fin (2^n) → ℂ`,
  the probability of outcome `b ∈ {0, 1}` is `∑ i with bit k of i = b, ‖ψ i‖²`.
  Uses `Finset.sum` and `Complex.normSq` / `‖·‖²`.

- **Verification cross-check:** Compare Lean semantics against `qir-runner` measurement
  outcome counts (not the full statevector). This avoids the Lean `ℂ` vs. Python
  `float64` comparison problem. For each outcome, the Lean-computed probability
  (summed over shots) is compared against the sampled frequency from `qir-runner`.

- **Adaptive Profile control flow:** Deferred to Phase 3. The formalization will
  need a CFG or structured control-flow representation for `i1` classical variables
  and conditional `br`. Base Profile avoids this entirely.

### Key Mathlib Modules

| Module | Used for |
|---|---|
| `Mathlib.Data.Matrix.Basic` | `Matrix`, `mulVec`, matrix arithmetic |
| `Mathlib.Data.Matrix.Kronecker` | `⊗ₖ` for embedding single-qubit gates |
| `Mathlib.Analysis.InnerProductSpace.Basic` | `EuclideanSpace`, inner products (Phase 2+) |
| `Mathlib.LinearAlgebra.UnitaryGroup` | `Matrix.unitaryGroup` (Phase 2+) |
| `Mathlib.LinearAlgebra.Matrix.ToLin` | `Matrix.toLin'` (Phase 2+) |
| `Mathlib.Algebra.BigOperators.Fin` | `finFunctionFinEquiv`, `Finset.sum` |
| `Mathlib.Data.Complex.Basic` | `ℂ`, `Complex.normSq` |

### Related Projects (Reference)

- **[inQWIRE/LeanQuantum](https://github.com/inQWIRE/LeanQuantum):** Lean 4 on Mathlib.
  Gates formalized (H, X, Y, Z, CNOT, rotations), Dirac notation (`∣0⟩`, `∣0⟩⟨1∣`),
  Pauli group, error correction. Good reference for gate matrix definitions.
- **[Timeroot/Lean-QuantumInfo](https://github.com/Timeroot/Lean-QuantumInfo):** 15k+ lines,
  250+ defs, 1000+ theorems. Includes teleportation formalization. Follows Mathlib
  naming conventions. Best reference for measurement and channel semantics.
