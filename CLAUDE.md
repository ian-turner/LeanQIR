# LeanQIR — Claude Instructions

## Wiki

This project maintains a knowledge base in `notes/`. **Read it before writing new code.**

| Page | Read when... |
|---|---|
| `notes/index.md` | Starting any task — quick orientation |
| `notes/project-overview.md` | Understanding goals, layout, and planned work |
| `notes/qir-primer.md` | Writing anything that touches QIR syntax or intrinsics |
| `notes/lean-formalization.md` | Working on the Lean source in `lean/` |
| `notes/simulation.md` | Writing or running simulation/verification code |

**Keep the wiki up to date.** When you make a change that affects any of the following, update the relevant notes page before finishing the task:

- Project structure (new files, directories, or renamed things)
- Planned work (decisions made, new plans added, plans completed)
- Lean module organization or design decisions
- Simulation tooling or verification strategy
- QIR coverage (new intrinsics modeled, new profiles handled)

Small changes (fixing a typo, tweaking a proof) don't need a wiki update. Structural or design-level changes do.

## Environment

- Python commands must use the `quantum` conda environment.
- Lean builds use Lake: `cd lean && lake build`.
- All Python simulation scripts live in `scripts/`; QIR example circuits live in `examples/`.
