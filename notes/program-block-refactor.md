# Program Block Refactor

Date: 2026-05-02

## Summary

`lean/LeanQIR/Syntax.lean` now owns the shared body/measurement program shape:

- `QubitRef n` and `ResultRef m` are the common static reference aliases.
- `BodyBlock` and `MeasurementBlock` capture instruction lists indexed by
  qubit/result counts.
- `ProgramBlocks` captures the common body-plus-measurements structure and
  provides `map` for erasing or translating between instruction layers.
- The circuit-level `Program` stores `ProgramBlocks GateInstr MeasInstr`.
- `BaseProgram` stores `ProgramBlocks BaseBodyInstr BaseMeasInstr`, while keeping
  QIR-only attributes, flags, entry, and output records in `QIR.Base`.

This removes the repeated program/block container definitions while preserving
the important distinction between the circuit-level instruction set and the
QIR Base Profile instruction subset.

## Why This Shape

The root program and QIR program should share structural machinery, but their
instruction types should not be merged yet. `BaseBodyInstr` intentionally
excludes `Reset` from the body block and carries Base-specific well-formedness
conditions such as distinct operands for two-qubit gates. Keeping the instruction
types separate avoids weakening the QIR model while eliminating boilerplate
around body and measurement lists.

## Next Steps

1. Add small theorem lemmas for `ProgramBlocks.map`, especially that it preserves
   body and measurement list lengths.
2. Add a `Program.WellFormed` predicate for circuit-level programs so root
   semantics can rule out invalid two-qubit operands just as `BaseProgram` does.
3. Consider a shared local well-formedness combinator for block predicates:
   `∀ instr ∈ block.instructions, p instr`.
4. Add concrete tests/proofs that `BaseProgram.toProgram` preserves the Bell
   body and measurements exactly.
5. Decide whether output records should be represented in the executable
   semantics or remain QIR-only metadata checked by `BaseProgram.WellFormed`.
