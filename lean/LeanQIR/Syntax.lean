import Mathlib.Data.Fin.Basic
import Mathlib.Data.Real.Basic

/-- Static qubit reference resolved against a program's declared qubit count. -/
abbrev QubitRef (n : ℕ) := Fin n

/-- Static result reference resolved against a program's declared result count. -/
abbrev ResultRef (m : ℕ) := Fin m

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
  | gate1  : Gate1  → QubitRef n → GateInstr n
  | gate1r : Gate1R → ℝ    → QubitRef n → GateInstr n
  | gate2  : Gate2  → QubitRef n → QubitRef n → GateInstr n  -- ctrl, tgt

/-- An instruction in the measurement block: measure qubit `qubit`, store
    the classical outcome in result slot `result`. -/
structure MeasInstr (n m : ℕ) : Type where
  qubit  : QubitRef n
  result : ResultRef m

/-- A block of body instructions parameterized by the program's qubit count. -/
structure BodyBlock (BodyInstr : ℕ → Type) (n : ℕ) : Type where
  instructions : List (BodyInstr n)

/-- A block of measurement instructions parameterized by qubit and result counts. -/
structure MeasurementBlock (MeasurementInstr : ℕ → ℕ → Type) (n m : ℕ) : Type where
  instructions : List (MeasurementInstr n m)

/-- Shared program body/measurement shape used by the circuit-level semantics
and by QIR-facing entry-point structures. -/
structure ProgramBlocks
    (BodyInstr : ℕ → Type)
    (MeasurementInstr : ℕ → ℕ → Type)
    (n m : ℕ) : Type where
  body : BodyBlock BodyInstr n
  measurements : MeasurementBlock MeasurementInstr n m

namespace ProgramBlocks

def bodyInstructions
    (blocks : ProgramBlocks BodyInstr MeasurementInstr n m) : List (BodyInstr n) :=
  blocks.body.instructions

def measurementInstructions
    (blocks : ProgramBlocks BodyInstr MeasurementInstr n m) : List (MeasurementInstr n m) :=
  blocks.measurements.instructions

def map
    {BodyInstr BodyInstr' : ℕ → Type}
    {MeasurementInstr MeasurementInstr' : ℕ → ℕ → Type}
    (bodyMap : ∀ {n : ℕ}, BodyInstr n → BodyInstr' n)
    (measurementMap : ∀ {n m : ℕ}, MeasurementInstr n m → MeasurementInstr' n m)
    (blocks : ProgramBlocks BodyInstr MeasurementInstr n m) :
    ProgramBlocks BodyInstr' MeasurementInstr' n m where
  body := { instructions := blocks.body.instructions.map bodyMap }
  measurements := { instructions := blocks.measurements.instructions.map measurementMap }

end ProgramBlocks

/-- A circuit-level program with `n` qubits and `m` result slots. -/
structure Program (n m : ℕ) : Type where
  blocks : ProgramBlocks GateInstr MeasInstr n m

namespace Program

/-- Build a circuit-level program from the two instruction lists used by the
semantics layer. -/
def ofLists (gates : List (GateInstr n)) (measurements : List (MeasInstr n m)) :
    Program n m where
  blocks :=
    { body := { instructions := gates }
      measurements := { instructions := measurements } }

def gates (program : Program n m) : List (GateInstr n) :=
  program.blocks.bodyInstructions

def measurements (program : Program n m) : List (MeasInstr n m) :=
  program.blocks.measurementInstructions

end Program
