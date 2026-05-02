import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-!
Backend-independent numeric operations for evaluator code.

`ScalarOps` is intentionally an operational dictionary rather than a typeclass
with algebraic laws. The `Float` instance is for approximate execution and
external simulator comparison, not for proof-level semantics.
-/

/-- Scalar operations needed by the shared evaluator.

The first pass only needs `sqrt` for constants such as `1 / sqrt 2`. Rotation
support can extend this dictionary with trigonometric operations later. -/
structure ScalarOps (α : Type) where
  zero : α
  one : α
  ofNat : Nat → α
  neg : α → α
  add : α → α → α
  sub : α → α → α
  mul : α → α → α
  div : α → α → α
  sqrt : α → α

namespace ScalarOps

/-- The proof-oriented real-number backend. -/
noncomputable def real : ScalarOps ℝ where
  zero := 0
  one := 1
  ofNat n := (n : ℝ)
  neg x := -x
  add x y := x + y
  sub x y := x - y
  mul x y := x * y
  div x y := x / y
  sqrt x := Real.sqrt x

/-- The approximate floating-point backend used for executable comparison. -/
def float : ScalarOps Float where
  zero := 0.0
  one := 1.0
  ofNat n := Float.ofNat n
  neg x := -x
  add x y := x + y
  sub x y := x - y
  mul x y := x * y
  div x y := x / y
  sqrt x := Float.sqrt x

end ScalarOps

/-- A small complex value type parameterized by its real scalar representation. -/
structure CVal (α : Type) where
  re : α
  im : α
  deriving Repr, DecidableEq

namespace CVal

variable {α : Type}

def zero (ops : ScalarOps α) : CVal α where
  re := ops.zero
  im := ops.zero

def one (ops : ScalarOps α) : CVal α where
  re := ops.one
  im := ops.zero

def I (ops : ScalarOps α) : CVal α where
  re := ops.zero
  im := ops.one

def ofScalar (ops : ScalarOps α) (x : α) : CVal α where
  re := x
  im := ops.zero

def neg (ops : ScalarOps α) (z : CVal α) : CVal α where
  re := ops.neg z.re
  im := ops.neg z.im

def add (ops : ScalarOps α) (z w : CVal α) : CVal α where
  re := ops.add z.re w.re
  im := ops.add z.im w.im

def sub (ops : ScalarOps α) (z w : CVal α) : CVal α where
  re := ops.sub z.re w.re
  im := ops.sub z.im w.im

def scale (ops : ScalarOps α) (a : α) (z : CVal α) : CVal α where
  re := ops.mul a z.re
  im := ops.mul a z.im

/-- Generic complex multiplication:
`(a + bi) * (c + di) = (ac - bd) + (ad + bc)i`. -/
def mul (ops : ScalarOps α) (z w : CVal α) : CVal α where
  re := ops.sub (ops.mul z.re w.re) (ops.mul z.im w.im)
  im := ops.add (ops.mul z.re w.im) (ops.mul z.im w.re)

/-- Squared norm of a complex value. -/
def normSq (ops : ScalarOps α) (z : CVal α) : α :=
  ops.add (ops.mul z.re z.re) (ops.mul z.im z.im)

def invSqrt2 (ops : ScalarOps α) : α :=
  ops.div ops.one (ops.sqrt (ops.ofNat 2))

end CVal
