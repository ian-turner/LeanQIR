import LeanQIR.QIR.Emit

/-- Bell-state Base Profile fixture matching the structure of `examples/bell.ll`. -/
def bellBase : BaseProgram 2 2 :=
  BaseProgram.qir2_0
    "main"
    "schema_id"
    [ BaseBodyInstr.gate1 .H 0
    , BaseBodyInstr.gate2 .CNOT 0 1
    ]
    [ { qubit := 0, result := 0 }
    , { qubit := 1, result := 1 }
    ]
    [ BaseOutputRecord.tuple 2 "bell"
    , BaseOutputRecord.result 0 "r0"
    , BaseOutputRecord.result 1 "r1"
    ]

theorem bellBase_wellFormed : bellBase.WellFormed := by
  unfold bellBase
  apply BaseProgram.qir2_0_wellFormed
  · intro instr h
    simp [BaseBodyInstr.WellFormed] at h ⊢
    rcases h with h | h
    · subst h
      trivial
    · subst h
      decide
  · intro record h
    simp [BaseOutputRecord.WellFormed, BaseOutputRecord.label] at h ⊢
    rcases h with h | h | h
    · subst h
      decide
    · subst h
      decide
    · subst h
      decide
  · decide

/-- LLVM IR text emitted from the Bell Base Profile fixture. -/
def bellLL : Except String String :=
  QIREmit.emitBaseProgram bellBase
