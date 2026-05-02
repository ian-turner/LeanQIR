import Mathlib.Data.Fin.Basic
import Mathlib.Data.Real.Basic

/-- Single-qubit Clifford/Pauli gates (no angle parameter). -/
inductive Gate1 : Type where
  | H | X | Y | Z | S | T | Reset
  deriving Repr, DecidableEq

/-- Single-qubit rotation gates parameterised by an angle θ : ℝ (radians). -/
inductive Gate1R : Type where
  | Rx | Ry | Rz
  deriving Repr, DecidableEq

/-- Two-qubit entangling gates. -/
inductive Gate2 : Type where
  | CNOT | CZ
  deriving Repr, DecidableEq

/-- An instruction in the unitary (body) block of a Base Profile program. -/
inductive GateInstr (n : ℕ) : Type where
  | gate1  : Gate1  → Fin n → GateInstr n
  | gate1r : Gate1R → ℝ    → Fin n → GateInstr n
  | gate2  : Gate2  → Fin n → Fin n → GateInstr n  -- ctrl, tgt

/-- An instruction in the measurement block: measure qubit `qubit`, store
    the classical outcome in result slot `result`. -/
structure MeasInstr (n m : ℕ) : Type where
  qubit  : Fin n
  result : Fin m

/-- A Base Profile program with `n` qubits and `m` result slots. -/
structure Program (n m : ℕ) : Type where
  gates        : List (GateInstr n)
  measurements : List (MeasInstr n m)
