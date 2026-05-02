# QIR Example Fixtures

The examples in `examples/` are intended to track the current QIR Alliance
profile syntax, not legacy typed-pointer QIR.

## Profile Targets

| File | Profile | Spec flags | Purpose |
|---|---|---|---|
| `examples/bell.ll` | Base Profile | `qir_major_version = 2`, `qir_minor_version = 0` | Four-block Base Profile fixture: initialize, unitary body, measurements, output |
| `examples/teleportation.ll` | Adaptive Profile | `qir_major_version = 2`, `qir_minor_version = 0` | Mid-circuit measurement and forward branching fixture |

## Conformance Notes

- Use opaque LLVM `ptr` for qubits, results, and labels.
- Entry points return `i64`; `0` is success.
- The first entry-point instruction is `__quantum__rt__initialize(ptr null)`.
- Output labels are non-null pointers to global null-terminated strings.
- Base Profile examples keep the official four-block shape:
  `entry -> body -> measurements -> output`.
- Adaptive Profile examples may branch on `i1` values returned by
  `__quantum__rt__read_result(ptr readonly ...)`, but should not use loops unless
  the `backwards_branching` module flag is enabled.

## Validation

Both examples currently run through `scripts/simulate.py`, which uses
`qir-runner` for sampling:

```bash
conda run -n quantum python scripts/simulate.py examples/bell.ll --shots 20 --seed 42
conda run -n quantum python scripts/simulate.py examples/teleportation.ll --shots 20 --seed 42
```
