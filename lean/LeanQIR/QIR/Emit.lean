import LeanQIR.QIR.Base

/-- Join pre-rendered LLVM lines with trailing newlines. -/
def joinLines (lines : List String) : String :=
  lines.foldr (fun line acc => line ++ "\n" ++ acc) ""

/-- Pair each list element with its zero-based position. -/
def enumerateFrom {α : Type} : Nat → List α → List (Nat × α)
  | _, [] => []
  | i, x :: xs => (i, x) :: enumerateFrom (i + 1) xs

namespace QIREmit

def emitPtrId (id : Nat) : String :=
  if id = 0 then
    "ptr null"
  else
    s!"ptr inttoptr (i64 {id} to ptr)"

def emitWriteonlyPtrId (id : Nat) : String :=
  if id = 0 then
    "ptr writeonly null"
  else
    s!"ptr writeonly inttoptr (i64 {id} to ptr)"

def emitQubitRef {n : ℕ} (qubit : QubitRef n) : String :=
  emitPtrId qubit.val

def emitResultRef {m : ℕ} (result : ResultRef m) : String :=
  emitPtrId result.val

def emitWriteonlyResultRef {m : ℕ} (result : ResultRef m) : String :=
  emitWriteonlyPtrId result.val

def emitBaseGate1Name : BaseGate1 → String
  | .H => "h"
  | .X => "x"
  | .Y => "y"
  | .Z => "z"
  | .S => "s"
  | .T => "t"

def emitBaseGate2Name : BaseGate2 → String
  | .CNOT => "cnot"
  | .CZ => "cz"

def emitBodyInstr {n : ℕ} : BaseBodyInstr n → Except String String
  | .gate1 gate qubit =>
      .ok s!"  call void @__quantum__qis__{emitBaseGate1Name gate}__body({emitQubitRef qubit})"
  | .gate1r _ _ _ =>
      .error "rotation emission is not implemented for real-valued angles yet"
  | .gate2 gate control target =>
      .ok s!"  call void @__quantum__qis__{emitBaseGate2Name gate}__body({emitQubitRef control}, {emitQubitRef target})"

def emitBodyBlock {n : ℕ} (body : BaseBodyBlock n) : Except String (List String) :=
  body.instructions.mapM emitBodyInstr

def emitMeasurementInstr {n m : ℕ} (instr : BaseMeasInstr n m) : String :=
  s!"  call void @__quantum__qis__mz__body({emitQubitRef instr.qubit}, {emitWriteonlyResultRef instr.result})"

def emitMeasurementBlock {n m : ℕ} (measurements : BaseMeasurementBlock n m) : List String :=
  measurements.instructions.map emitMeasurementInstr

/-- The first emitter pass supports plain ASCII-ish labels used by our fixtures.
It handles the essential LLVM terminator, but does not yet escape arbitrary
Unicode or control characters. -/
def emitCString (label : String) : String :=
  label ++ "\\00"

def labelByteLength (label : String) : Nat :=
  label.length + 1

def emitLabelGlobal {m : ℕ} (entry : Nat × BaseOutputRecord m) : String :=
  let (id, record) := entry
  let label := record.label
  s!"@{id} = internal constant [{labelByteLength label} x i8] c\"{emitCString label}\""

def emitOutputRecord {m : ℕ} (entry : Nat × BaseOutputRecord m) : String :=
  let (id, record) := entry
  match record with
  | .tuple size _ =>
      s!"  call void @__quantum__rt__tuple_record_output(i64 {size}, ptr @{id})"
  | .array size _ =>
      s!"  call void @__quantum__rt__array_record_output(i64 {size}, ptr @{id})"
  | .result result _ =>
      s!"  call void @__quantum__rt__result_record_output({emitResultRef result}, ptr @{id})"

def emitOutputBlock {m : ℕ} (output : BaseOutputBlock m) : List String :=
  (enumerateFrom 0 output.records).map emitOutputRecord

def moduleFlagBehaviorCode : ModuleFlagBehavior → Nat
  | .error => 1
  | .warning => 2
  | .append => 5
  | .appendUnique => 6
  | .max => 7

def emitBool (value : Bool) : String :=
  if value then "true" else "false"

def emitModuleFlags (flags : BaseModuleFlags) : List String :=
  [ "!llvm.module.flags = !{!0, !1, !2, !3}"
  , "!0 = !{i32 " ++ toString (moduleFlagBehaviorCode flags.qirMajorBehavior) ++
      ", !\"qir_major_version\", i32 " ++ toString flags.qirMajorVersion ++ "}"
  , "!1 = !{i32 " ++ toString (moduleFlagBehaviorCode flags.qirMinorBehavior) ++
      ", !\"qir_minor_version\", i32 " ++ toString flags.qirMinorVersion ++ "}"
  , "!2 = !{i32 " ++ toString (moduleFlagBehaviorCode flags.dynamicQubitBehavior) ++
      ", !\"dynamic_qubit_management\", i1 " ++ emitBool flags.dynamicQubitManagement ++ "}"
  , "!3 = !{i32 " ++ toString (moduleFlagBehaviorCode flags.dynamicResultBehavior) ++
      ", !\"dynamic_result_management\", i1 " ++ emitBool flags.dynamicResultManagement ++ "}"
  ]

def emitDeclarations : List String :=
  [ "declare void @__quantum__rt__initialize(ptr)"
  , "declare void @__quantum__rt__tuple_record_output(i64, ptr)"
  , "declare void @__quantum__rt__array_record_output(i64, ptr)"
  , "declare void @__quantum__rt__result_record_output(ptr, ptr)"
  , ""
  , "declare void @__quantum__qis__h__body(ptr)"
  , "declare void @__quantum__qis__x__body(ptr)"
  , "declare void @__quantum__qis__y__body(ptr)"
  , "declare void @__quantum__qis__z__body(ptr)"
  , "declare void @__quantum__qis__s__body(ptr)"
  , "declare void @__quantum__qis__t__body(ptr)"
  , "declare void @__quantum__qis__cnot__body(ptr, ptr)"
  , "declare void @__quantum__qis__cz__body(ptr, ptr)"
  , "declare void @__quantum__qis__mz__body(ptr, ptr writeonly) #1"
  ]

def emitEntryAttributes (attrs : BaseEntryAttrs) : String :=
  "attributes #0 = { \"entry_point\" \"qir_profiles\"=\"" ++ attrs.qirProfiles ++
    "\" \"output_labeling_schema\"=\"" ++ attrs.outputLabelingSchema ++
    "\" \"required_num_qubits\"=\"" ++ toString attrs.requiredNumQubits ++
    "\" \"required_num_results\"=\"" ++ toString attrs.requiredNumResults ++ "\" }"

def emitAttributes (attrs : BaseEntryAttrs) : List String :=
  [ emitEntryAttributes attrs
  , "attributes #1 = { \"irreversible\" }"
  ]

/-- Emit a structured QIR Base Profile program as LLVM IR text.

The result is textual `.ll` for the supported non-rotational Base subset. The
function returns an error instead of emitting rotations because the current
abstract syntax stores rotation angles as `ℝ`, which does not carry a computable
LLVM floating-point spelling. -/
def emitBaseProgram {n m : ℕ} (program : BaseProgram n m) : Except String String := do
  let bodyLines ← emitBodyBlock program.body
  let outputEntries := enumerateFrom 0 program.output.records
  let labelLines := outputEntries.map emitLabelGlobal
  let lines :=
    labelLines ++
    [ ""
    , "define i64 @" ++ program.attrs.name ++ "() #0 {"
    , "entry:"
    , "  call void @__quantum__rt__initialize(ptr null)"
    , "  br label %body"
    , ""
    , "body:"
    ] ++
    bodyLines ++
    [ "  br label %measurements"
    , ""
    , "measurements:"
    ] ++
    emitMeasurementBlock program.measurements ++
    [ "  br label %output"
    , ""
    , "output:"
    ] ++
    emitOutputBlock program.output ++
    [ s!"  ret i64 {program.output.returnCode}"
    , "}"
    , ""
    ] ++
    emitDeclarations ++
    [ "" ] ++
    emitAttributes program.attrs ++
    [ "" ] ++
    emitModuleFlags program.flags
  pure (joinLines lines)

end QIREmit
