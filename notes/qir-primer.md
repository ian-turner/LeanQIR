# QIR Primer

QIR (Quantum Intermediate Representation) is an LLVM-based IR for quantum programs,
maintained by the [QIR Alliance](https://github.com/qir-alliance/qir-spec).

## Core Idea

A backend combines a quantum processor (QPU) with classical computing resources.
A QIR program is a mix of:

- **QIS instructions** — quantum operations that run on the QPU (`__quantum__qis__*`)
- **Runtime functions** — classical operations and data transfer (`__quantum__rt__*`)
- **LLVM instructions** — classical control flow and arithmetic

The **profile** determines which LLVM instructions and runtime functions are valid.
The **Quantum Instruction Set (QIS)** determines which quantum gates the backend
supports. Profiles and QIS are chosen independently. The spec does **not** mandate
a specific gate set — each backend declares what it supports.

## Module Structure

Every QIR bitcode file contains:

1. Opaque type definitions for `Qubit` and `Result`
2. Global string constants (null-terminated, for output labels)
3. The entry point function
4. QIS function declarations
5. Runtime function declarations
6. Attribute groups (entry point metadata)
7. Module flags metadata

The entry point function:
- Takes **no parameters**
- Returns `i64` exit code (0 = success, 1–63 = program failure)
- First instruction must call `@__quantum__rt__initialize(ptr null)`

## Qubit and Result Representation

Qubits and results are opaque pointers (`ptr`). Two modes:

**Static allocation (default):** A constant integer is cast to a pointer:
```llvm
inttoptr (i64 N to ptr)    ; qubit/result N
ptr null                   ; shorthand for qubit/result 0
```
Integer N must be in `[0, numQubits)` for qubits, `[0, numResults)` for results.
These values are declared in entry point attributes.

**Dynamic allocation (optional):** Pointers returned from runtime allocator calls
identify resources. Requires `dynamic_qubit_management` / `dynamic_result_management`
module flags set to `true`.

Neither kind of pointer is ever dereferenced by program code; only runtime
implementations dereference them.

## Profiles

### Base Profile

Minimal profile. Execution model:
1. Initialize all qubits to |0⟩
2. Apply unitary gates (non-irreversible QIS calls)
3. Measure all qubits at end (irreversible QIS calls)
4. Record output

**Entry point structure** — exactly four basic blocks in sequence:
```
entry → body → measurements → output
```
- `entry`: `__quantum__rt__initialize`, unconditional branch to body
- `body`: unitary QIS calls only
- `measurements`: irreversible QIS calls (measurements) only
- `output`: output recording calls + `ret i64 0`

No mid-circuit measurement. No classical control flow on results.

**Permitted LLVM instructions** (only these five):

| Instruction | Purpose |
|---|---|
| `call` | Invoke QIS and runtime functions |
| `br` | Unconditional branch between blocks |
| `ret` | Return exit code (final block only) |
| `inttoptr` | Cast `i64` to `ptr` (inline in call args only) |
| `getelementptr inbounds` | Build string ptr for output label (in output recording calls only) |

**Full example:**
```llvm
@0 = internal constant [3 x i8] c"r1\00"
@1 = internal constant [3 x i8] c"r2\00"
@2 = internal constant [3 x i8] c"t0\00"

define i64 @Entry_Point_Name() #0 {
entry:
  call void @__quantum__rt__initialize(ptr null)
  br label %body
body:
  call void @__quantum__qis__h__body(ptr null)
  call void @__quantum__qis__cnot__body(ptr null, ptr inttoptr (i64 1 to ptr))
  br label %measurements
measurements:
  call void @__quantum__qis__mz__body(ptr null, ptr writeonly null)
  call void @__quantum__qis__mz__body(ptr inttoptr (i64 1 to ptr), ptr writeonly inttoptr (i64 1 to ptr))
  br label %output
output:
  call void @__quantum__rt__tuple_record_output(i64 2, ptr @2)
  call void @__quantum__rt__result_record_output(ptr null, ptr @0)
  call void @__quantum__rt__result_record_output(ptr inttoptr (i64 1 to ptr), ptr @1)
  ret i64 0
}

declare void @__quantum__qis__h__body(ptr)
declare void @__quantum__qis__cnot__body(ptr, ptr)
declare void @__quantum__qis__mz__body(ptr, ptr writeonly) #1

declare void @__quantum__rt__initialize(ptr)
declare void @__quantum__rt__tuple_record_output(i64, ptr)
declare void @__quantum__rt__result_record_output(ptr, ptr)

attributes #0 = { "entry_point" "qir_profiles"="base_profile"
                  "output_labeling_schema"="schema_id"
                  "required_num_qubits"="2" "required_num_results"="2" }
attributes #1 = { "irreversible" }

!llvm.module.flags = !{!0, !1, !2, !3}
!0 = !{i32 1, !"qir_major_version", i32 2}
!1 = !{i32 7, !"qir_minor_version", i32 0}
!2 = !{i32 1, !"dynamic_qubit_management", i1 false}
!3 = !{i32 1, !"dynamic_result_management", i1 false}
```

### Adaptive Profile

Extends Base Profile with mid-circuit measurement and classical control flow.

**Mandatory capabilities (1–4):**
1. Quantum state transformations (same as Base)
2. Mid-circuit measurements — any qubit can be measured at any point; unmeasured
   qubits are unaffected
3. Forward branching — convert result to `i1` via `__quantum__rt__read_result`,
   then use conditional `br`; arbitrary nesting required
4. Output recording (same as Base)

**Optional capabilities (5–11):**

| Bullet | Capability | Module flag |
|---|---|---|
| 5 | Integer / float arithmetic | `int_computations`, `float_computations` |
| 6 | IR-defined subroutines (no recursion) | `ir_functions` |
| 7 | Backward branching (loops) | `backwards_branching` (i2: 0=none, 1=iterations, 2=cond, 3=both) |
| 8 | `switch` instruction | `multiple_target_branching` |
| 9 | Multiple return points | `multiple_return_points` |
| 10 | Dynamic qubit/result allocation | `dynamic_qubit_management`, `dynamic_result_management` |
| 11 | LLVM array types for qubits/results | `arrays` |

**Additional LLVM instructions available in Adaptive Profile:**

For integer computations: `add`, `sub`, `mul`, `udiv`, `sdiv`, `urem`, `srem`,
`and`, `or`, `xor`, `shl`, `lshr`, `ashr`, `icmp`, `zext`, `sext`, `trunc`,
`select`, `phi`.

For float computations: `fadd`, `fsub`, `fmul`, `fdiv`, `fcmp`, `fpext`, `fptrunc`.

For multiple-target branching: `switch`.

**Key pattern — mid-circuit measurement + conditional gate:**
```llvm
  tail call void @__quantum__qis__mz__body(ptr null, ptr writeonly null)
  %0 = tail call i1 @__quantum__rt__read_result(ptr readonly null)
  br i1 %0, label %then, label %continue
then:
  tail call void @__quantum__qis__x__body(ptr null)
  br label %continue
continue:
  ...
```

## QIS Function Requirements

For Base Profile compatibility:
- All QIS functions must return `void`
- Measurement functions must be marked `#{ "irreversible" }`
- Result pointer parameters must be `writeonly`

For Adaptive Profile, QIS functions may additionally:
- Return classical data types (if Bullet 5 enabled)
- Take values of any type as arguments

The spec does not mandate any specific gates. Common gates seen in examples:
`h`, `x`, `y`, `z`, `s`, `t`, `cnot`, `cz`, `rx`, `ry`, `rz`, `mz`, `mresetz`, `reset`.

Naming convention: `__quantum__qis__<gate>__body`

## Runtime Functions

### Always required (both profiles)

| Function | Signature | Description |
|---|---|---|
| `__quantum__rt__initialize` | `void(ptr)` | Init environment; zero all static qubits |
| `__quantum__rt__tuple_record_output` | `void(i64, ptr)` | Mark tuple start + element count in output |
| `__quantum__rt__array_record_output` | `void(i64, ptr)` | Mark array start + element count in output |
| `__quantum__rt__result_record_output` | `void(ptr, ptr)` | Record a measurement result |

### Adaptive Profile additions

| Function | Signature | Description |
|---|---|---|
| `__quantum__rt__read_result` | `i1(ptr readonly)` | Convert result ptr to boolean `i1` |
| `__quantum__rt__bool_record_output` | `void(i1, ptr)` | Record a boolean value |
| `__quantum__rt__int_record_output` | `void(i64, ptr)` | Record an integer (requires Bullet 5) |
| `__quantum__rt__float_record_output` | `void(f64, ptr)` | Record a float (requires Bullet 5) |

### Dynamic allocation (Bullet 10)

```llvm
declare ptr  @__quantum__rt__qubit_allocate(ptr %out_err)
declare void @__quantum__rt__qubit_release(ptr %qubit)
declare ptr  @__quantum__rt__result_allocate(ptr %out_err)
declare void @__quantum__rt__result_release(ptr %result)
```
- `%out_err = null`: allocation failure terminates the program
- `%out_err ≠ null`: must point to an `i1`; set to `true` on failure, `false` on success

### Arrays + dynamic allocation (Bullets 10 + 11)

```llvm
declare void @__quantum__rt__qubit_array_allocate(i64 %N, ptr %array, ptr %out_err)
declare void @__quantum__rt__qubit_array_release(i64 %N, ptr %array)
declare void @__quantum__rt__result_array_allocate(i64 %N, ptr %array, ptr %out_err)
declare void @__quantum__rt__result_array_release(i64 %N, ptr %array)
declare void @__quantum__rt__result_array_record_output(i64 %N, ptr %result_array, ptr %tag)
```
The caller allocates the array buffer (typically via `alloca`); the runtime
manages the quantum resources inside it.

## Module Flags

### Required by both profiles

| Flag | Type | Behavior | Meaning |
|---|---|---|---|
| `qir_major_version` | `i32` | Error | Breaking change boundary (must match) |
| `qir_minor_version` | `i32` | Max | Backward-compatible; merged = higher version |
| `dynamic_qubit_management` | `i1` | Error | Whether dynamic qubit alloc is used |
| `dynamic_result_management` | `i1` | Error | Whether dynamic result alloc is used |

### Optional (Adaptive Profile only)

| Flag | Type | Meaning |
|---|---|---|
| `int_computations` | metadata tuple | Integer widths used (e.g. `{!"i32", !"i64"}`) |
| `float_computations` | metadata tuple | Float widths used (e.g. `{!"float", !"double"}`) |
| `ir_functions` | `i1` | Whether IR-defined subroutines are used |
| `backwards_branching` | `i2` | 0=none, 1=iterations, 2=cond loops, 3=both |
| `multiple_target_branching` | `i1` | Whether `switch` is used |
| `multiple_return_points` | `i1` | Whether multiple `ret` statements are used |
| `arrays` | `i1` | Whether LLVM array types are used |

## Entry Point Attributes

Required on the entry point function:

| Attribute | Value | Meaning |
|---|---|---|
| `"entry_point"` | (flag) | Marks this as the program entry point |
| `"qir_profiles"` | `"base_profile"` or `"adaptive_profile"` | Profile targeted |
| `"required_num_qubits"` | string-encoded i64 | Number of static qubits needed |
| `"required_num_results"` | string-encoded i64 | Max stored measurement results |
| `"output_labeling_schema"` | string | Frontend-defined label format identifier |

Not required when dynamic qubit/result management is enabled (the corresponding
`required_num_*` attribute may be omitted).

## Output Schemas

Backends produce output using one of two schemas:

- **Ordered** — for synchronous backends; values in declaration order, no labels
- **Labeled** — for asynchronous backends; values with their string labels

The schema is identified by a header record in the produced output, not in the IR.
Each output recording function gets a unique null-terminated string label. Labels
must be unique within an entry point. Backends may ignore labels depending on the
chosen schema.

## Versioning

Current spec: **QIR 2.1** (released 2026-03-25).
QIR v2.0+ requires LLVM 16+. QIR v1.0 used LLVM 15 or earlier.
v2.0 toolchains can consume v1.0 programs; the reverse is not supported.

## References

- [QIR Spec](https://github.com/qir-alliance/qir-spec) — Base Profile, Adaptive Profile,
  Instruction Set, Memory Management, Output Schemas
- [qir-runner](https://github.com/qir-alliance/qir-runner) — reference executor
