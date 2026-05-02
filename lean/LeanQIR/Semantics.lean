import Mathlib.Analysis.SpecialFunctions.Pow.Real
import LeanQIR.Syntax
import LeanQIR.State

open BigOperators Real

/-! ## Classical bitstrings -/

/-- An m-bit classical measurement outcome: a function Fin m → Bool. -/
def BitString (m : ℕ) := Fin m → Bool

/-! ## Single-qubit measurement -/

/-- Project qubit k onto outcome b, returning the (normalised) post-measurement
    state and the probability of that outcome.
    Probability: Σ_{i : bit_k(i) = b} ‖ψ i‖².
    Post-state: the projected (and renormalised) vector. -/
noncomputable def measureQubit {n : ℕ} (k : Fin n) (b : Fin 2) (ψ : Statevector n) :
    Statevector n × ℝ :=
  let prob : ℝ :=
    ∑ i : Fin (2 ^ n), if getBit i k = b then Complex.normSq (ψ i) else 0
  let projected : Statevector n := fun i =>
    if getBit i k = b then ψ i else 0
  let postState : Statevector n := fun i =>
    if prob = 0 then 0 else projected i / (Real.sqrt prob : ℂ)
  (postState, prob)

/-! ## Gate-block evaluation (pure unitary evolution) -/

/-- Apply the list of gate instructions to ψ, left-to-right. -/
noncomputable def evalGates {n : ℕ} : List (GateInstr n) → Statevector n → Statevector n
  | [],              ψ => ψ
  | instr :: rest,   ψ =>
      let ψ' := match instr with
        | .gate1  g k      => applyGate1 k (gate1Mat g) ψ
        | .gate1r g θ k    => applyGate1 k (gate1rMat g θ) ψ
        | .gate2  g ctrl t => applyGate2 ctrl t (gate2Mat g) ψ
      evalGates rest ψ'

/-! ## Measurement-block evaluation (branching over outcomes) -/

/-- One step of measurement evaluation: expand each branch by measuring the next qubit,
    producing two new branches (outcome 0 and outcome 1). -/
private noncomputable def evalMeasStep {n m : ℕ} (instr : MeasInstr n m)
    (branches : List (Statevector n × BitString m × ℝ)) :
    List (Statevector n × BitString m × ℝ) :=
  branches.flatMap fun ⟨ψ, bs, p⟩ =>
    List.ofFn (n := 2) fun b : Fin 2 =>
      let (ψ', prob) := measureQubit instr.qubit b ψ
      (ψ', Function.update bs instr.result (b = ⟨1, by norm_num⟩), p * prob)

/-- Evaluate the measurement block, returning one entry per possible outcome combination.
    Start from a single branch with the full pre-measurement state and probability 1. -/
noncomputable def evalMeasurements {n m : ℕ}
    (instrs : List (MeasInstr n m)) (ψ₀ : Statevector n) :
    List (Statevector n × BitString m × ℝ) :=
  instrs.foldl (fun branches instr => evalMeasStep instr branches)
    [(ψ₀, fun _ => false, 1)]

/-! ## Top-level evaluator -/

/-- Evaluate a Base Profile program from initial state |0...0⟩.
    Returns a list of (post-state, outcome bitstring, probability) triples,
    one per possible measurement outcome combination. -/
noncomputable def eval {n m : ℕ} (p : Program n m) :
    List (Statevector n × BitString m × ℝ) :=
  evalMeasurements p.measurements (evalGates p.gates (initState n))
