import LeanQIR.Syntax

/-- Static qubit reference used by Base Profile programs.

In Base Profile QIR, qubits are represented by `ptr` constants encoding integer
ids in the range `[0, required_num_qubits)`. This resolved Lean layer represents
those ids directly as bounded indices. -/
abbrev QubitRef (n : ℕ) := Fin n

/-- Static result reference used by Base Profile programs.

In Base Profile QIR, result slots are represented by `ptr` constants encoding
integer ids in the range `[0, required_num_results)`. -/
abbrev ResultRef (m : ℕ) := Fin m

/-- QIR module flag merge behavior for the flags modeled here. -/
inductive ModuleFlagBehavior where
  | error
  | max
  | warning
  | append
  | appendUnique
  deriving Repr, DecidableEq

/-- The module flags required by QIR Base Profile.

The Base Profile requires QIR version flags and forbids dynamic qubit/result
management. -/
structure BaseModuleFlags where
  qirMajorVersion : ℕ
  qirMajorBehavior : ModuleFlagBehavior
  qirMinorVersion : ℕ
  qirMinorBehavior : ModuleFlagBehavior
  dynamicQubitManagement : Bool
  dynamicQubitBehavior : ModuleFlagBehavior
  dynamicResultManagement : Bool
  dynamicResultBehavior : ModuleFlagBehavior
  deriving Repr, DecidableEq

namespace BaseModuleFlags

/-- The current QIR 2.0 Base Profile module flags used by the official examples. -/
def qir2_0 : BaseModuleFlags where
  qirMajorVersion := 2
  qirMajorBehavior := .error
  qirMinorVersion := 0
  qirMinorBehavior := .max
  dynamicQubitManagement := false
  dynamicQubitBehavior := .error
  dynamicResultManagement := false
  dynamicResultBehavior := .error

/-- Compliance predicate for the QIR 2.0 Base Profile flags modeled here. -/
def WellFormed (flags : BaseModuleFlags) : Prop :=
  flags.qirMajorVersion = 2 ∧
  flags.qirMajorBehavior = .error ∧
  flags.qirMinorVersion = 0 ∧
  flags.qirMinorBehavior = .max ∧
  flags.dynamicQubitManagement = false ∧
  flags.dynamicQubitBehavior = .error ∧
  flags.dynamicResultManagement = false ∧
  flags.dynamicResultBehavior = .error

theorem qir2_0_wellFormed : qir2_0.WellFormed := by
  simp [WellFormed, qir2_0]

end BaseModuleFlags

/-- Entry-point attributes required by QIR Base Profile.

The qubit/result counts are intentionally stored as attributes, rather than only
as type indices, so that well-formedness can state that the source-level QIR
metadata agrees with the resolved Lean representation. -/
structure BaseEntryAttrs where
  name : String
  qirProfiles : String
  outputLabelingSchema : String
  requiredNumQubits : ℕ
  requiredNumResults : ℕ
  deriving Repr, DecidableEq

namespace BaseEntryAttrs

/-- Construct the standard Base Profile entry-point attributes for a resolved
program with `n` qubits and `m` result slots. -/
def base (name outputLabelingSchema : String) (n m : ℕ) : BaseEntryAttrs where
  name := name
  qirProfiles := "base_profile"
  outputLabelingSchema := outputLabelingSchema
  requiredNumQubits := n
  requiredNumResults := m

/-- Base Profile attribute consistency for a program resolved to `n` qubits and
`m` result slots. -/
def WellFormed (attrs : BaseEntryAttrs) (n m : ℕ) : Prop :=
  attrs.qirProfiles = "base_profile" ∧
  attrs.requiredNumQubits = n ∧
  attrs.requiredNumResults = m

theorem base_wellFormed (name outputLabelingSchema : String) (n m : ℕ) :
    (base name outputLabelingSchema n m).WellFormed n m := by
  simp [WellFormed, base]

end BaseEntryAttrs

/-- The Base Profile entry block. In raw QIR this block contains runtime
initialization calls and branches unconditionally to the body block. -/
structure BaseEntryBlock where
  initializesRuntime : Bool
  deriving Repr, DecidableEq

namespace BaseEntryBlock

/-- The standard QIR Base Profile entry block containing
`__quantum__rt__initialize(ptr null)`. -/
def initialized : BaseEntryBlock where
  initializesRuntime := true

def WellFormed (entry : BaseEntryBlock) : Prop :=
  entry.initializesRuntime = true

theorem initialized_wellFormed : initialized.WellFormed := by
  simp [WellFormed, initialized]

end BaseEntryBlock

/-- Non-irreversible single-qubit gates currently modeled for Base Profile body
blocks. `Reset` is intentionally excluded because it is not a unitary body
operation. -/
inductive BaseGate1 where
  | H | X | Y | Z | S | T
  deriving Repr, DecidableEq

namespace BaseGate1

def toGate1 : BaseGate1 → Gate1
  | .H => .H
  | .X => .X
  | .Y => .Y
  | .Z => .Z
  | .S => .S
  | .T => .T

end BaseGate1

/-- Two-qubit gates currently modeled for Base Profile body blocks. -/
inductive BaseGate2 where
  | CNOT | CZ
  deriving Repr, DecidableEq

namespace BaseGate2

def toGate2 : BaseGate2 → Gate2
  | .CNOT => .CNOT
  | .CZ => .CZ

end BaseGate2

/-- A non-irreversible QIS call in the Base Profile body block. -/
inductive BaseBodyInstr (n : ℕ) where
  | gate1 : BaseGate1 → QubitRef n → BaseBodyInstr n
  | gate1r : Gate1R → ℝ → QubitRef n → BaseBodyInstr n
  | gate2 : BaseGate2 → QubitRef n → QubitRef n → BaseBodyInstr n

namespace BaseBodyInstr

def toGateInstr {n : ℕ} : BaseBodyInstr n → GateInstr n
  | .gate1 g q => .gate1 g.toGate1 q
  | .gate1r g θ q => .gate1r g θ q
  | .gate2 g c t => .gate2 g.toGate2 c t

/-- Structural validity beyond type-correct qubit references.

The Base Profile itself requires qubits to be valid static references. That is
already enforced by `Fin n`; for our concrete two-qubit gates we additionally
rule out using the same qubit as both operands. -/
def WellFormed {n : ℕ} : BaseBodyInstr n → Prop
  | .gate1 _ _ => True
  | .gate1r _ _ _ => True
  | .gate2 _ control target => control ≠ target

end BaseBodyInstr

/-- The Base Profile body block: non-irreversible QIS calls followed by an
unconditional branch to the measurement block. -/
structure BaseBodyBlock (n : ℕ) where
  instructions : List (BaseBodyInstr n)

namespace BaseBodyBlock

def WellFormed {n : ℕ} (body : BaseBodyBlock n) : Prop :=
  ∀ instr ∈ body.instructions, instr.WellFormed

end BaseBodyBlock

/-- An irreversible measurement call in the Base Profile measurement block.

This corresponds to `__quantum__qis__mz__body(qubit, result writeonly)` for the
QIS subset modeled so far. -/
structure BaseMeasInstr (n m : ℕ) where
  qubit : QubitRef n
  result : ResultRef m
  deriving Repr, DecidableEq

namespace BaseMeasInstr

def toMeasInstr {n m : ℕ} (instr : BaseMeasInstr n m) : MeasInstr n m where
  qubit := instr.qubit
  result := instr.result

end BaseMeasInstr

/-- The Base Profile measurement block: irreversible QIS calls followed by an
unconditional branch to the output block. -/
structure BaseMeasurementBlock (n m : ℕ) where
  instructions : List (BaseMeasInstr n m)
  deriving Repr, DecidableEq

/-- Runtime output-recording calls supported by Base Profile. Each call carries
the non-null string label that raw QIR passes as a global string pointer. -/
inductive BaseOutputRecord (m : ℕ) where
  | tuple : (size : ℕ) → (label : String) → BaseOutputRecord m
  | array : (size : ℕ) → (label : String) → BaseOutputRecord m
  | result : ResultRef m → (label : String) → BaseOutputRecord m
  deriving Repr, DecidableEq

namespace BaseOutputRecord

def label {m : ℕ} : BaseOutputRecord m → String
  | .tuple _ label => label
  | .array _ label => label
  | .result _ label => label

def isResult {m : ℕ} : BaseOutputRecord m → Bool
  | .result _ _ => true
  | _ => false

/-- Output-record validity that is local to one record. Type indices enforce
result-reference bounds; the label condition models the Base Profile requirement
that output labels are non-null strings. -/
def WellFormed {m : ℕ} (record : BaseOutputRecord m) : Prop :=
  record.label ≠ ""

end BaseOutputRecord

/-- The Base Profile output block: runtime output-recording calls followed by
`ret i64 0`. -/
structure BaseOutputBlock (m : ℕ) where
  records : List (BaseOutputRecord m)
  returnCode : ℤ
  deriving Repr, DecidableEq

namespace BaseOutputBlock

def labels {m : ℕ} (output : BaseOutputBlock m) : List String :=
  output.records.map BaseOutputRecord.label

def WellFormed {m : ℕ} (output : BaseOutputBlock m) : Prop :=
  output.returnCode = 0 ∧
  (∀ record ∈ output.records, record.WellFormed) ∧
  output.labels.Nodup

end BaseOutputBlock

/-- A structured representation of a QIR Base Profile entry point.

Raw LLVM block names and textual ordering are intentionally absent: this type is
the resolved structure after checking that the entry point has the Base Profile
four-block control-flow shape:

`entry → body → measurements → output → ret i64 0`.
-/
structure BaseProgram (n m : ℕ) where
  attrs : BaseEntryAttrs
  flags : BaseModuleFlags
  entry : BaseEntryBlock
  body : BaseBodyBlock n
  measurements : BaseMeasurementBlock n m
  output : BaseOutputBlock m

namespace BaseProgram

/-- A complete Base Profile well-formedness predicate for the QIR structure
modeled so far. Bounded qubit/result references and the four-block shape are
enforced by the type itself; this predicate checks metadata and local constraints
that are not convenient to encode as fields. -/
def WellFormed {n m : ℕ} (program : BaseProgram n m) : Prop :=
  program.attrs.WellFormed n m ∧
  program.flags.WellFormed ∧
  program.entry.WellFormed ∧
  program.body.WellFormed ∧
  program.output.WellFormed

/-- Erase the QIR Base Profile structure into the earlier circuit-level program
used by the current statevector semantics. Output records and metadata are not
semantic in that older layer, so they are checked by `WellFormed` rather than
preserved here. -/
def toProgram {n m : ℕ} (program : BaseProgram n m) : Program n m where
  gates := program.body.instructions.map BaseBodyInstr.toGateInstr
  measurements := program.measurements.instructions.map BaseMeasInstr.toMeasInstr

/-- Convenience constructor for Base Profile programs that target QIR 2.0. -/
def qir2_0
    (name outputLabelingSchema : String)
    (body : List (BaseBodyInstr n))
    (measurements : List (BaseMeasInstr n m))
    (output : List (BaseOutputRecord m)) : BaseProgram n m where
  attrs := BaseEntryAttrs.base name outputLabelingSchema n m
  flags := BaseModuleFlags.qir2_0
  entry := BaseEntryBlock.initialized
  body := { instructions := body }
  measurements := { instructions := measurements }
  output := { records := output, returnCode := 0 }

theorem qir2_0_wellFormed
    {n m : ℕ}
    {name outputLabelingSchema : String}
    {body : List (BaseBodyInstr n)}
    {measurements : List (BaseMeasInstr n m)}
    {output : List (BaseOutputRecord m)}
    (hBody : ∀ instr ∈ body, instr.WellFormed)
    (hOutputRecords : ∀ record ∈ output, record.WellFormed)
    (hOutputLabels : (output.map BaseOutputRecord.label).Nodup) :
    (qir2_0 name outputLabelingSchema body measurements output).WellFormed := by
  constructor
  · exact BaseEntryAttrs.base_wellFormed name outputLabelingSchema n m
  constructor
  · exact BaseModuleFlags.qir2_0_wellFormed
  constructor
  · exact BaseEntryBlock.initialized_wellFormed
  constructor
  · exact hBody
  · exact ⟨rfl, hOutputRecords, hOutputLabels⟩

end BaseProgram
