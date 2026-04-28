# Simulation & Verification

## Tools

### qir-runner (sampling)

Used by `scripts/simulate.py` to run `.ll` files and collect measurement outcome counts.

```bash
# Run in the `quantum` conda env
conda run -n quantum python scripts/simulate.py examples/bell.ll
python scripts/simulate.py examples/bell.ll --shots 100 --seed 42
```

Output format: `|bitstring>: count`

### MQT DDSIM (statevector / density matrix)

Used to extract the full quantum state for comparison against semantic rules.

```python
from mqt.core.dd import simulate_statevector
import numpy as np

sv = simulate_statevector(circuit)
rho = np.outer(sv, sv.conj())  # pure-state density matrix
```

- Package: `mqt-ddsim 2.2.0`, `mqt-core 3.4.1`
- Environment: `quantum` conda env
- `pyddsim.DeterministicNoiseSimulator` is available for noisy simulation but density matrix extraction from it needs further investigation.

## Verification Strategy

The plan is to run the Lean semantics on a circuit (or a small fragment) and compare the resulting state against MQT DDSIM's output. A match on a suite of circuits gives confidence the semantic rules are correct before attempting formal proofs.

Steps:
1. Define a circuit fragment in both Lean and a Python test
2. Run the Lean evaluator (likely via a `#eval` or extracted code)
3. Run MQT DDSIM on the same circuit
4. Compare density matrices (up to numerical tolerance)
