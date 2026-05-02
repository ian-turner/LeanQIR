# QIR Base Emitter

`lean/LeanQIR/QIR/Emit.lean` contains the first Lean-native emitter from
structured Base Profile programs to textual LLVM IR (`.ll`).

The main entry point is:

```lean
QIREmit.emitBaseProgram : BaseProgram n m -> Except String String
```

It emits the current supported non-rotational Base subset:

- Static qubit/result references as `ptr null` for id 0 and
  `ptr inttoptr (i64 N to ptr)` for later ids.
- The four Base Profile blocks: `entry`, `body`, `measurements`, and `output`.
- QIS calls for `h`, `x`, `y`, `z`, `s`, `t`, `cnot`, `cz`, and final `mz`.
- Runtime calls for initialization and tuple/array/result output records.
- Entry-point attributes and QIR 2.0 module flags from `BaseProgram`.

`lean/LeanQIR/Examples/Bell.lean` defines `bellBase : BaseProgram 2 2`, proves
`bellBase_wellFormed`, and exposes `bellLL`.

`lean/LeanQIR/CLI/EmitBell.lean` is a tiny Lake executable:

```bash
cd lean
lake exe emit_bell > /tmp/leanqir-bell.ll
```

Validation performed for the current implementation:

```bash
cd lean
lake build
lake exe emit_bell
llvm-as /tmp/leanqir-bell.ll -o /tmp/leanqir-bell.bc
conda run -n quantum python scripts/simulate.py /tmp/leanqir-bell.ll --shots 20 --seed 42
```

The simulator accepted the emitted Bell program and produced correlated Bell
outcomes (`00` and `11` only).

## Current Limitations

- Rotation instructions are rejected with an `Except.error`. The current
  abstract syntax stores rotation angles as `ℝ`, which does not provide a
  computable LLVM floating-point spelling. A future emitter-friendly angle type
  should preserve both mathematical value and concrete text, for example a
  decimal/rational literal plus an interpretation as `ℝ`.
- String labels are emitted for the plain ASCII labels used by the fixtures and
  append `\00`. General LLVM string escaping for quotes, backslashes, control
  bytes, and Unicode is not implemented yet.
- The emitter declares the supported QIS/runtime surface as a superset instead
  of minimizing declarations to only the intrinsics used by a program.
- The CLI currently emits only the Bell fixture. A generic executable should
  eventually select named Lean fixtures or read a serialized abstract program.
