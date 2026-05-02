# QIR Base Structure

The Lean formalization now has a first QIR-facing Base Profile layer in
`lean/LeanQIR/QIR/Base.lean`.

This layer is intentionally more faithful to the QIR Base Profile than the
earlier circuit-level `Program`:

- `BaseProgram n m` represents the four Base Profile regions:
  `entry -> body -> measurements -> output`.
- The body and measurement regions use the shared `ProgramBlocks` container from
  `LeanQIR.Syntax`, specialized to `BaseBodyInstr` and `BaseMeasInstr`.
- Static qubit and result references are represented as `Fin n` and `Fin m`,
  corresponding to the integer ids encoded in non-dynamic QIR `ptr` values.
- `BaseEntryAttrs` stores entry-point metadata such as `qir_profiles`,
  `required_num_qubits`, `required_num_results`, and
  `output_labeling_schema`.
- `BaseModuleFlags` stores the required QIR version and dynamic-management
  flags. `BaseModuleFlags.qir2_0` models the current QIR 2.0 flags used by the
  example fixtures.
- `BaseBodyInstr` excludes `Reset`, so the body block only contains modeled
  non-irreversible QIS calls.
- `BaseMeasInstr` models final `mz`-style irreversible measurement calls.
- `BaseOutputRecord` models tuple, array, and result output-recording runtime
  calls with string labels.
- `BaseProgram.WellFormed` checks metadata agreement, runtime initialization,
  body-instruction validity, output label validity/uniqueness, and `ret i64 0`.

The type itself enforces the four-block shape and bounded qubit/result
references. The well-formedness predicate is used for conditions that are more
convenient as propositions, such as module flag values and unique output labels.

`BaseProgram.toProgram` erases a well-structured Base Profile program into the
older circuit-level `Program n m` used by the current statevector semantics. The
output block and QIR metadata are not preserved in that older semantics layer
yet; they are represented and checked in the Base layer.

`LeanQIR.QIR.Emit` now provides the inverse engineering path for the supported
subset: a structured `BaseProgram n m` can be emitted as textual LLVM IR and fed
to `llvm-as` or `qir-runner`. The first fixture is `bellBase` in
`Examples.Bell`, printable with `lake exe emit_bell`.

## Next Steps

- Add more concrete Lean fixtures corresponding to checked-in `.ll` examples.
- Decide whether output recording should become part of the executable
  semantics, rather than only a structural validity condition.
- Replace raw `ℝ` rotation angles with a representation that can support both
  proofs and concrete LLVM floating-point emission.
- Add an elaboration/checking layer from a raw LLVM-like syntax into
  `BaseProgram n m` if we want to reason about malformed QIR modules directly.
