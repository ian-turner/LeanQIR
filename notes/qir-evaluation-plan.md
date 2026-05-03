# QIR Evaluation Plan

## Current Structure

The Lean project already has two useful layers:

- `LeanQIR.QIR.Base` represents a resolved QIR Base Profile entry point as
  `BaseProgram n m`. It preserves the QIR-facing four-block shape:
  `entry -> body -> measurements -> output`.
- `LeanQIR.Syntax` and `LeanQIR.Semantics` provide the older circuit-level
  execution layer. `BaseProgram.toProgram` erases a `BaseProgram` into that
  lower-level `Program n m`.

The current evaluator is mathematically clean but not executable in the form we
need for a CLI:

- `Statevector n` is `Fin (2 ^ n) -> Complex`.
- Gate matrices are mathlib matrices over `Complex`.
- `Semantics.eval` returns
  `List (Statevector n × BitString m × Real)`.
- The evaluator is `noncomputable`, because it uses `Real`, `Complex`,
  `Real.sqrt`, finite sums over mathlib structures, and theorem-oriented
  definitions.

This is a good proof semantics, but it cannot directly drive a Lean executable
that prints floating-point probabilities.

The QIR-facing output block is also not semantic yet. Output records are checked
by `BaseProgram.WellFormed`, but `BaseProgram.toProgram` drops labels and output
shape before evaluation. For stdout probabilities we need a small executable
presentation layer that reconnects measured result slots to output labels or to
bitstring keys.

## Target

Support a Lean executable that runs an abstract Base Profile program and writes
measurement outcome probabilities to stdout, for example:

```text
00 0.5
01 0.0
10 0.0
11 0.5
```

The first target should be checked-in abstract fixtures such as `bellBase`, not
parsing arbitrary `.ll`. Parsing raw QIR can remain a separate later phase.

## Design Direction

Do not build a detached Float simulator. Instead, factor the evaluator into a
shared gate/statevector algorithm with multiple numeric backends:

- an abstract backend over mathlib `Complex`/`Real`, used for formal semantics
  and proofs;
- a `Float` backend, used only for approximate comparison against external
  simulators and for stdout output.

The shared evaluator should define the control flow, indexing convention, gate
application order, and measurement-probability accumulation exactly once. The
numeric backend supplies the scalar operations and constants.

`Float` must not be treated as a lawful field. Floating-point arithmetic is
rounded and non-associative, so the proof story should be:

1. Prove the generic evaluator instantiated with the abstract backend matches
   the existing `LeanQIR.Semantics` definitions.
2. Use the Float backend as an approximation implementation for testing against
   DDSIM/qir-runner.
3. Optionally add approximation relations and error bounds later.

## Proposed Modules

- `LeanQIR/Numeric.lean`

  Backend-independent numeric interfaces and a small complex structure. This
  module should avoid QIR-specific concepts.

- `LeanQIR/Evaluator.lean`

  Generic statevector and probability-table evaluation parameterized by a
  numeric backend.

- `LeanQIR/QIR/Eval.lean`

  Thin QIR-facing wrappers from `BaseProgram n m` into the generic evaluator.

- `Examples/BellEval.lean`

  First CLI executable that evaluates `bellBase` and prints probabilities.

## Concrete Numeric Shape

Start with one complex-amplitude type that can be interpreted over both
abstract and Float scalars:

```lean
structure CVal (α : Type) where
  re : α
  im : α
```

Then define a small operation dictionary. Keep it intentionally operational;
do not require algebraic laws for the Float instance.

```lean
structure ScalarOps (α : Type) where
  zero : α
  one : α
  ofNat : Nat -> α
  neg : α -> α
  add : α -> α -> α
  sub : α -> α -> α
  mul : α -> α -> α
  div : α -> α -> α
  sqrt : α -> α
```

For the first non-rotational slice, `sqrt` is enough for the Hadamard constant
`1 / sqrt 2`. Rotation gates can be rejected initially. When rotations are
enabled, extend the operation dictionary with `sin`, `cos`, and perhaps `pi`.

Define complex operations generically from `ScalarOps`:

- `CVal.zero`, `CVal.one`, `CVal.I`
- `CVal.add`, `CVal.sub`, `CVal.neg`, `CVal.mul`
- `CVal.scale`
- `CVal.normSq : CVal α -> α`

Backend instances:

- `ScalarOps Real`, noncomputable, for proof semantics.
- `ScalarOps Float`, computable, for approximate execution.

## Generic Evaluator Shape

Use arrays for the shared algorithm because they line up with executable output
and still have a clean abstract interpretation when instantiated with `Real`.

```lean
abbrev GState (α : Type) := Array (CVal α)

def initState (ops : ScalarOps α) (n : Nat) : GState α
def getBitNat (index qubit : Nat) : Nat
def setBitNat (index qubit bit : Nat) : Nat
def applyGate1 (ops : ScalarOps α) (n : Nat) ...
def applyGate2 (ops : ScalarOps α) (n : Nat) ...
def evalBody (ops : ScalarOps α) ...
def evalProbabilities (ops : ScalarOps α) ...
```

The first implementation can return `Except String` rather than proving array
length invariants immediately:

```lean
def evalProgramGeneric
    (ops : ScalarOps α)
    {n m : Nat}
    (body : List (BaseBodyInstr n))
    (measurements : List (BaseMeasInstr n m)) :
    Except String (Array α)
```

The returned array has length `2 ^ m`, indexed by measurement-result bitstring.
Formatting into `(String × α)` belongs in the QIR wrapper or CLI, not in the
generic evaluator.

## Measurement Probability Algorithm

For the Base subset, measurements happen after all unitary body instructions.
So the generic probability evaluator should avoid branch-by-branch collapse and
compute final probabilities directly:

1. Evaluate the body gates from `|0...0>`.
2. Allocate a probability array of length `2 ^ m` filled with `zero`.
3. For each basis index `i` in `0...(2 ^ n - 1)`:
   - read amplitude `ψ[i]`;
   - compute `p = normSq ψ[i]`;
   - compute the result-index induced by measurement instructions:
     `resultBit[result] := getBitNat i qubit`;
   - add `p` to that probability bucket.
4. Return all buckets in deterministic numeric order.

This algorithm should be the same for the `Real` and `Float` backends.

## Proof Plan

The proof-facing work should be incremental:

1. Define conversion between array states and existing functional states:

   ```lean
   def arrayStateToFun {n : Nat} (state : GState Real) :
       Fin (2 ^ n) -> Complex
   ```

   Or use `CVal Real` directly first and add a later bridge to mathlib
   `Complex`.

2. Prove the bit-index helpers match:

   - `getBitNat i.val q.val` agrees with existing `getBit i q`;
   - `setBitNat i.val q.val b` agrees with existing `setBit i q b`.

3. Prove generic single-gate application with the `Real` backend agrees with
   the existing matrix-based definitions in `LeanQIR.State` for H, X, Y, Z, S,
   T, CNOT, and CZ.

4. Lift the single-gate result to `evalBody` by list induction.

5. Prove direct final-probability accumulation agrees with
   `Semantics.evalMeasurements` after summing branches by bitstring. The
   existing semantics returns post-measurement states too, so the correspondence
   theorem should project out only probabilities.

The first implementation does not need all proofs complete before the CLI
exists, but the code should be shaped so these statements are natural.

## Float Verification Role

The Float backend should expose:

```lean
def evalBaseProbabilitiesFloat {n m : Nat} :
    BaseProgram n m -> Except String (Array (String × Float))
```

This is for:

- printing approximate probabilities to stdout;
- comparing Lean's executable path against qir-runner or DDSIM;
- smoke-testing examples while the formal proofs target the abstract backend.

It is not the semantic definition used for theorems.

## CLI Plan

Add an executable:

```toml
[[lean_exe]]
name = "eval_bell"
root = "Examples.BellEval"
```

`Examples.BellEval.main` should:

1. call `evalBaseProbabilitiesFloat bellBase`;
2. print one line per outcome;
3. return `1` on `Except.error`.

Recommended initial output:

```text
00 0.4999999999999999
01 0.0
10 0.0
11 0.4999999999999999
```

Keep zero-probability outcomes in the first version because dense output is
easier to compare against the returned array and external simulator fixtures.

## Rotation Handling

Current abstract syntax stores rotation angles as `Real`, which cannot be
computed by the Float backend. Do not blur this boundary.

First slice:

- reject `BaseBodyInstr.gate1r` in the generic evaluator with a clear error.

Later options:

- introduce an `Angle` structure that stores both a proof value and an optional
  executable approximation;
- parameterize instruction syntax by angle representation;
- keep abstract QIR programs over `Real` and provide a separate checked
  elaboration step into executable fixtures with Float angles.

## Open Decisions

- Whether result slot `0` should print as the leftmost or rightmost bit. Pick
  one before implementing `bitstringOfIndex`, document it, and keep tests
  consistent.
- Whether `LeanQIR.Evaluator` should use arrays permanently or later expose a
  theorem-oriented vector/function wrapper.
- Whether to bridge `CVal Real` to mathlib `Complex` immediately or first prove
  internal properties over `CVal Real`.
- Whether output labels should be included after the raw probability table works.

## Recommended First Slice

Implement non-rotational Bell evaluation through the shared generic path:

1. Add `LeanQIR.Numeric` with `CVal`, generic complex operations, `ScalarOps
   Real`, and `ScalarOps Float`.
2. Add `LeanQIR.Evaluator` with generic body evaluation and final probability
   accumulation.
3. Add `LeanQIR.QIR.Eval` wrappers:

   ```lean
   noncomputable def evalBaseProbabilitiesReal ...
   def evalBaseProbabilitiesFloat ...
   ```

4. Add `Examples.BellEval` and `lake exe eval_bell`.
5. Add a lightweight note or README command documenting the executable.
6. Add the first proof lemmas only for bit-index agreement and H/CNOT behavior;
   leave full evaluator correspondence as the next proof milestone.

This gives us a single evaluator structure with two numeric interpretations:
abstract for semantics, Float for approximate simulator comparison.

## Implementation Log

### 2026-05-02: Pass 1 Numeric Core

Added `LeanQIR.Numeric` with:

- `ScalarOps α`, an operational scalar dictionary with no algebraic laws;
- `ScalarOps.real`, a noncomputable proof-oriented `Real` backend;
- `ScalarOps.float`, a computable approximate `Float` backend;
- `CVal α`, a small complex-amplitude structure;
- generic complex operations over `ScalarOps`, including `normSq` and
  `invSqrt2`.

`Float` remains intentionally law-free. It is for executable comparison and
stdout output, while proof work should target the real backend and later bridge
to the existing mathlib `Complex` semantics.

### 2026-05-02: Pass 2 Generic Evaluator Skeleton

Added `LeanQIR.Evaluator` with:

- `Evaluator.GState α`, a dense array statevector over generic complex
  amplitudes;
- executable bit helpers `getBitNat` and `setBitNat`, using result/qubit slot 0
  as the least-significant bit;
- generic application for Base non-rotational gates `H`, `X`, `Y`, `Z`, `S`,
  `T`, `CNOT`, and `CZ`;
- explicit rejection of `gate1r` rotation instructions until executable angle
  representation is designed;
- final probability accumulation over the measurement block into a dense array
  indexed by result bitstring bucket.

This pass keeps the evaluator independent of stdout formatting and QIR output
records. The next wrapper pass should expose `evalBaseProbabilitiesReal` and
`evalBaseProbabilitiesFloat` for `BaseProgram n m`.
