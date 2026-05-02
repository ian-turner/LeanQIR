import Mathlib.Data.Complex.Basic
import Mathlib.Data.Matrix.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import LeanQIR.Syntax

open Complex Matrix BigOperators

/-! ## Statevectors -/

/-- An n-qubit pure state: complex amplitudes indexed by basis states Fin (2^n). -/
noncomputable def Statevector (n : ℕ) := Fin (2 ^ n) → ℂ

/-- Initial state |0...0⟩: amplitude 1 at index 0, 0 elsewhere. -/
noncomputable def initState (n : ℕ) : Statevector n :=
  fun i => if i.val = 0 then 1 else 0

/-! ## Gate matrices -/

private noncomputable def invSqrt2 : ℂ := ((Real.sqrt 2)⁻¹ : ℝ)

noncomputable def hMat : Matrix (Fin 2) (Fin 2) ℂ :=
  !![invSqrt2, invSqrt2; invSqrt2, -invSqrt2]

noncomputable def xMat : Matrix (Fin 2) (Fin 2) ℂ := !![0, 1; 1, 0]
noncomputable def yMat : Matrix (Fin 2) (Fin 2) ℂ := !![0, -I; I, 0]
noncomputable def zMat : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, -1]
noncomputable def sMat : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, I]
noncomputable def tMat : Matrix (Fin 2) (Fin 2) ℂ :=
  !![1, 0; 0, exp (I * ↑Real.pi / 4)]

noncomputable def rxMat (θ : ℝ) : Matrix (Fin 2) (Fin 2) ℂ :=
  !![↑(Real.cos (θ / 2)),              -I * ↑(Real.sin (θ / 2));
     -I * ↑(Real.sin (θ / 2)),         ↑(Real.cos (θ / 2))]

noncomputable def ryMat (θ : ℝ) : Matrix (Fin 2) (Fin 2) ℂ :=
  !![↑(Real.cos (θ / 2)),   -(↑(Real.sin (θ / 2)) : ℂ);
     ↑(Real.sin (θ / 2)),    ↑(Real.cos (θ / 2))]

noncomputable def rzMat (θ : ℝ) : Matrix (Fin 2) (Fin 2) ℂ :=
  !![exp (-I * ↑θ / 2), 0;
     0,                  exp (I * ↑θ / 2)]

-- CNOT: rows/cols indexed by (ctrl_bit * 2 + tgt_bit)
noncomputable def cnotMat : Matrix (Fin 4) (Fin 4) ℂ :=
  !![1, 0, 0, 0;
     0, 1, 0, 0;
     0, 0, 0, 1;
     0, 0, 1, 0]

noncomputable def czMat : Matrix (Fin 4) (Fin 4) ℂ :=
  !![1, 0, 0,  0;
     0, 1, 0,  0;
     0, 0, 1,  0;
     0, 0, 0, -1]

/-- Dispatch Gate1 → 2×2 matrix. Reset's special semantics are handled at the
    semantics layer; here it maps to the identity. -/
noncomputable def gate1Mat : Gate1 → Matrix (Fin 2) (Fin 2) ℂ
  | .H     => hMat
  | .X     => xMat
  | .Y     => yMat
  | .Z     => zMat
  | .S     => sMat
  | .T     => tMat
  | .Reset => !![1, 0; 0, 1]

noncomputable def gate1rMat : Gate1R → ℝ → Matrix (Fin 2) (Fin 2) ℂ
  | .Rx, θ => rxMat θ
  | .Ry, θ => ryMat θ
  | .Rz, θ => rzMat θ

noncomputable def gate2Mat : Gate2 → Matrix (Fin 4) (Fin 4) ℂ
  | .CNOT => cnotMat
  | .CZ   => czMat

/-! ## Bit-level index helpers -/

/-- Extract bit k of basis index i: (i / 2^k) % 2. -/
def getBit {n : ℕ} (i : Fin (2 ^ n)) (k : Fin n) : Fin 2 :=
  ⟨(i.val / 2 ^ k.val) % 2, by omega⟩

/-- Replace bit k of basis index i with b.
    Decomposition: i = high * 2^(k+1) + old_bit * 2^k + low → result replaces old_bit. -/
def setBit {n : ℕ} (i : Fin (2 ^ n)) (k : Fin n) (b : Fin 2) : Fin (2 ^ n) :=
  ⟨i.val / 2 ^ (k.val + 1) * 2 ^ (k.val + 1) + b.val * 2 ^ k.val + i.val % 2 ^ k.val, by
    have hKp  : 0 < 2 ^ k.val       := by positivity
    have hK1p : 0 < 2 ^ (k.val + 1) := by positivity
    have hmod : i.val % 2 ^ k.val < 2 ^ k.val := Nat.mod_lt _ hKp
    have hpow : 2 ^ (k.val + 1) * 2 ^ (n - k.val - 1) = 2 ^ n := by
      rw [← Nat.pow_add]; congr 1; omega
    have hdiv : i.val / 2 ^ (k.val + 1) < 2 ^ (n - k.val - 1) := by
      rw [Nat.div_lt_iff_lt_mul hK1p, Nat.mul_comm, hpow]; exact i.isLt
    have hexpand : i.val / 2 ^ (k.val + 1) * 2 ^ (k.val + 1) + 2 ^ (k.val + 1) ≤ 2 ^ n := by
      have hstep : (i.val / 2 ^ (k.val + 1) + 1) * 2 ^ (k.val + 1) ≤ 2 ^ n := by
        calc (i.val / 2 ^ (k.val + 1) + 1) * 2 ^ (k.val + 1)
            ≤ 2 ^ (n - k.val - 1) * 2 ^ (k.val + 1) := by
                apply mul_le_mul_of_nonneg_right (Nat.succ_le_of_lt hdiv) (Nat.zero_le _)
          _ = 2 ^ (k.val + 1) * 2 ^ (n - k.val - 1) := by ring
          _ = 2 ^ n := hpow
      linarith [show (i.val / 2 ^ (k.val + 1) + 1) * 2 ^ (k.val + 1) =
                     i.val / 2 ^ (k.val + 1) * 2 ^ (k.val + 1) + 2 ^ (k.val + 1) from by ring]
    have hK1 : 2 ^ (k.val + 1) = 2 * 2 ^ k.val := by ring
    have hBK : b.val * 2 ^ k.val ≤ 2 ^ k.val := by nlinarith [b.isLt]
    nlinarith⟩

/-! ## Gate application -/

/-- Apply a single-qubit gate G to qubit k of n-qubit state ψ.
    (applyGate1 k G ψ) i = Σ b : Fin 2, G[bit_k(i), b] * ψ(setBit i k b) -/
noncomputable def applyGate1 {n : ℕ} (k : Fin n) (G : Matrix (Fin 2) (Fin 2) ℂ)
    (ψ : Statevector n) : Statevector n :=
  fun i => ∑ b : Fin 2, G (getBit i k) b * ψ (setBit i k b)

/-- Apply a two-qubit gate G to qubits ctrl and tgt.
    Row/col index: ctrl_bit * 2 + tgt_bit. -/
noncomputable def applyGate2 {n : ℕ} (ctrl tgt : Fin n) (G : Matrix (Fin 4) (Fin 4) ℂ)
    (ψ : Statevector n) : Statevector n :=
  fun i =>
    let row : Fin 4 := ⟨(getBit i ctrl).val * 2 + (getBit i tgt).val, by
      have := (getBit i ctrl).isLt; have := (getBit i tgt).isLt; omega⟩
    ∑ bc : Fin 2, ∑ bt : Fin 2,
      G row ⟨bc.val * 2 + bt.val, by have := bc.isLt; have := bt.isLt; omega⟩ *
      ψ (setBit (setBit i ctrl bc) tgt bt)
