# QIR Primer

QIR (Quantum Intermediate Representation) is an LLVM-based IR for quantum programs, maintained by the [QIR Alliance](https://github.com/qir-alliance/qir-spec).

## Key Concepts

- QIR files are LLVM IR (`.ll` text, `.bc` bitcode)
- Qubits and results are opaque pointer types: `%Qubit*`, `%Result*`
- Qubits are indexed by casting integers to pointers: `inttoptr (i64 N to %Qubit*)`
- Quantum operations are calls to named intrinsics (`__quantum__qis__*`)
- Classical runtime calls are `__quantum__rt__*`

## Profiles

| Profile | Description |
|---|---|
| Base Profile | No mid-circuit measurement, no classical control flow on results |
| Adaptive Profile | Mid-circuit measurement + classical branching (`read_result`, `br`) |

Both examples in this repo are used:
- `bell.ll` — Base Profile
- `teleportation.ll` — Adaptive Profile

## Common Intrinsics

| Intrinsic | Operation |
|---|---|
| `__quantum__qis__h__body` | Hadamard |
| `__quantum__qis__cnot__body` | CNOT |
| `__quantum__qis__x__body` | Pauli X |
| `__quantum__qis__z__body` | Pauli Z |
| `__quantum__qis__mz__body` | Measure in Z basis (destructive) |
| `__quantum__qis__read_result__body` | Read result as classical `i1` |
| `__quantum__rt__result_record_output` | Record a result for output |

## References

- [QIR Spec](https://github.com/qir-alliance/qir-spec)
- [qir-runner](https://github.com/qir-alliance/qir-runner)
