"""
Run a QIR .ll file with qir-runner and print measurement outcome counts.

Usage:
    python simulate.py circuits/bell.ll
    python simulate.py circuits/bell.ll --shots 20
    python simulate.py circuits/bell.ll --shots 5 --seed 42
"""

import argparse
from collections import Counter
import qirrunner


def parse_output(raw: str) -> list[list[str]]:
    """Parse qir-runner output into per-shot measurement result lists."""
    shots = []
    current = []
    for line in raw.splitlines():
        if line == "START":
            current = []
        elif line.startswith("OUTPUT\tRESULT\t"):
            current.append(line.split("\t")[2])
        elif line.startswith("END"):
            if current:
                shots.append(current)
    return shots


def main():
    parser = argparse.ArgumentParser(description="Simulate a QIR file with qir-runner")
    parser.add_argument("path", help="Path to a .ll or .bc QIR file")
    parser.add_argument("--shots", type=int, default=10)
    parser.add_argument("--seed", type=int, default=None)
    args = parser.parse_args()

    handler = qirrunner.OutputHandler()
    qirrunner.run(args.path, shots=args.shots, rng_seed=args.seed, output_fn=handler.handle)

    shots = parse_output(handler.get_output())

    counts = Counter(" ".join(r) for r in shots)

    print(f"File:  {args.path}")
    print(f"Shots: {args.shots}")
    print()
    for outcome, count in sorted(counts.items()):
        print(f"  |{''.join(outcome.split(' '))}>: {count}")


if __name__ == "__main__":
    main()
