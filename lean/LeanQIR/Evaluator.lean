import LeanQIR.Numeric
import LeanQIR.QIR.Base

/-!
Generic statevector evaluation for resolved QIR Base Profile programs.

This module owns the shared executable algorithm. It is parameterized by
`ScalarOps`, so the same control flow and indexing convention can run over a
proof-oriented real backend or the approximate `Float` backend.
-/

namespace Evaluator

/-- Dense statevector represented by basis-indexed amplitudes. -/
abbrev GState (α : Type) := Array (CVal α)

/-- Number of computational-basis amplitudes for `n` qubits. -/
def stateSize (n : Nat) : Nat :=
  2 ^ n

/-- Extract bit `qubit` from a computational-basis index. Qubit/result slot 0 is
the least-significant bit throughout this evaluator. -/
def getBitNat (index qubit : Nat) : Nat :=
  (index / 2 ^ qubit) % 2

/-- Replace bit `qubit` in `index` with `bit`.

This is the executable counterpart of `LeanQIR.State.setBit`, without carrying
the proof that the result is still within the finite basis range. -/
def setBitNat (index qubit bit : Nat) : Nat :=
  index / 2 ^ (qubit + 1) * 2 ^ (qubit + 1) +
    bit * 2 ^ qubit +
    index % 2 ^ qubit

def initState (ops : ScalarOps α) (n : Nat) : GState α :=
  ((List.range (stateSize n)).map fun index =>
    if index = 0 then CVal.one ops else CVal.zero ops).toArray

private def getAmp (ops : ScalarOps α) (state : GState α) (index : Nat) : CVal α :=
  state.getD index (CVal.zero ops)

private def mulI (ops : ScalarOps α) (z : CVal α) : CVal α where
  re := ops.neg z.im
  im := z.re

private def mulNegI (ops : ScalarOps α) (z : CVal α) : CVal α where
  re := z.im
  im := ops.neg z.re

private def tPhase (ops : ScalarOps α) : CVal α where
  re := CVal.invSqrt2 ops
  im := CVal.invSqrt2 ops

private def applyGate1AtIndex
    (ops : ScalarOps α)
    (gate : BaseGate1)
    (qubit : Nat)
    (state : GState α)
    (index : Nat) : CVal α :=
  let bit := getBitNat index qubit
  let a0 := getAmp ops state (setBitNat index qubit 0)
  let a1 := getAmp ops state (setBitNat index qubit 1)
  match gate with
  | .H =>
      let scale := CVal.invSqrt2 ops
      if bit = 0 then
        CVal.scale ops scale (CVal.add ops a0 a1)
      else
        CVal.scale ops scale (CVal.sub ops a0 a1)
  | .X =>
      if bit = 0 then a1 else a0
  | .Y =>
      if bit = 0 then mulNegI ops a1 else mulI ops a0
  | .Z =>
      if bit = 0 then a0 else CVal.neg ops a1
  | .S =>
      if bit = 0 then a0 else mulI ops a1
  | .T =>
      if bit = 0 then a0 else CVal.mul ops (tPhase ops) a1

def applyGate1
    (ops : ScalarOps α)
    (n : Nat)
    (gate : BaseGate1)
    (qubit : Nat)
    (state : GState α) : GState α :=
  ((List.range (stateSize n)).map fun index =>
    applyGate1AtIndex ops gate qubit state index).toArray

private def applyGate2AtIndex
    (ops : ScalarOps α)
    (gate : BaseGate2)
    (control target : Nat)
    (state : GState α)
    (index : Nat) : CVal α :=
  match gate with
  | .CNOT =>
      if getBitNat index control = 0 then
        getAmp ops state index
      else
        let targetBit := getBitNat index target
        getAmp ops state (setBitNat index target (1 - targetBit))
  | .CZ =>
      if getBitNat index control = 1 ∧ getBitNat index target = 1 then
        CVal.neg ops (getAmp ops state index)
      else
        getAmp ops state index

def applyGate2
    (ops : ScalarOps α)
    (n : Nat)
    (gate : BaseGate2)
    (control target : Nat)
    (state : GState α) : GState α :=
  ((List.range (stateSize n)).map fun index =>
    applyGate2AtIndex ops gate control target state index).toArray

def evalBodyInstr
    (ops : ScalarOps α)
    {n : Nat}
    (state : GState α) :
    BaseBodyInstr n → Except String (GState α)
  | .gate1 gate qubit =>
      .ok (applyGate1 ops n gate qubit.val state)
  | .gate1r _ _ _ =>
      .error "rotation gates are not supported by the generic evaluator yet"
  | .gate2 gate control target =>
      .ok (applyGate2 ops n gate control.val target.val state)

def evalBody
    (ops : ScalarOps α)
    {n : Nat}
    (body : List (BaseBodyInstr n))
    (state : GState α) : Except String (GState α) :=
  body.foldlM (fun state instr => evalBodyInstr ops state instr) state

/-- Result-bucket index induced by the measurement block for one basis state.

Result slot 0 is the least-significant bit of the returned bucket index. -/
def resultIndexOfBasis
    {n m : Nat}
    (measurements : List (BaseMeasInstr n m))
    (basisIndex : Nat) : Nat :=
  measurements.foldl
    (fun resultIndex instr =>
      setBitNat resultIndex instr.result.val (getBitNat basisIndex instr.qubit.val))
    0

def addProbability
    (ops : ScalarOps α)
    (probabilities : Array α)
    (bucket : Nat)
    (probability : α) : Array α :=
  probabilities.modify bucket (fun old => ops.add old probability)

def probabilitiesOfState
    (ops : ScalarOps α)
    {n m : Nat}
    (measurements : List (BaseMeasInstr n m))
    (state : GState α) : Array α :=
  (List.range (stateSize n)).foldl
    (fun probabilities basisIndex =>
      let bucket := resultIndexOfBasis measurements basisIndex
      let probability := CVal.normSq ops (getAmp ops state basisIndex)
      addProbability ops probabilities bucket probability)
    (Array.replicate (stateSize m) ops.zero)

/-- Evaluate body gates from `|0...0>` and accumulate final measurement
probabilities into a dense result-bucket table. -/
def evalProgramGeneric
    (ops : ScalarOps α)
    {n m : Nat}
    (body : List (BaseBodyInstr n))
    (measurements : List (BaseMeasInstr n m)) :
    Except String (Array α) := do
  let state ← evalBody ops body (initState ops n)
  .ok (probabilitiesOfState ops measurements state)

end Evaluator
