# LeanQIR

A Lean 4 formalization of the semantics of [QIR](https://github.com/qir-alliance/qir-spec) (Quantum Intermediate Representation), with simulation-based verification via [qir-runner](https://github.com/qir-alliance/qir-runner).

## Structure

```
examples/   QIR circuit files (.ll)
scripts/    Python simulation utilities
```

## Simulation

Requires the `quantum` conda environment with `qirrunner` installed.

```bash
python scripts/simulate.py examples/bell.ll
python scripts/simulate.py examples/teleportation.ll --shots 100 --seed 42
```
