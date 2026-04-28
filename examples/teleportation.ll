; Quantum teleportation
;
; Qubits:
;   q0 = state to teleport (prepared as |+> = H|0>)
;   q1, q2 = Bell pair (shared channel)
;
; Protocol:
;   1. Prepare |+> on q0
;   2. Create Bell pair on q1, q2
;   3. Bell measurement on q0, q1 -> m0, m1
;   4. Classical corrections on q2: X if m1=1, Z if m0=1
;   5. Measure q2 -> should match original state (50/50 for |+>)
;
; QIR Adaptive Profile v1

%Qubit = type opaque
%Result = type opaque

define void @main() #0 {
entry:
  ; Prepare state to teleport: |+> on q0
  call void @__quantum__qis__h__body(%Qubit* null)

  ; Create Bell pair on q1, q2
  call void @__quantum__qis__h__body(%Qubit* inttoptr (i64 1 to %Qubit*))
  call void @__quantum__qis__cnot__body(%Qubit* inttoptr (i64 1 to %Qubit*), %Qubit* inttoptr (i64 2 to %Qubit*))

  ; Bell measurement on q0, q1
  call void @__quantum__qis__cnot__body(%Qubit* null, %Qubit* inttoptr (i64 1 to %Qubit*))
  call void @__quantum__qis__h__body(%Qubit* null)
  call void @__quantum__qis__mz__body(%Qubit* null, %Result* null)
  call void @__quantum__qis__mz__body(%Qubit* inttoptr (i64 1 to %Qubit*), %Result* inttoptr (i64 1 to %Result*))

  ; Read measurement results for classical control
  %m0 = call i1 @__quantum__qis__read_result__body(%Result* null)
  %m1 = call i1 @__quantum__qis__read_result__body(%Result* inttoptr (i64 1 to %Result*))

  ; X correction on q2 if m1 = 1
  br i1 %m1, label %apply_x, label %skip_x
apply_x:
  call void @__quantum__qis__x__body(%Qubit* inttoptr (i64 2 to %Qubit*))
  br label %skip_x
skip_x:
  ; Z correction on q2 if m0 = 1
  br i1 %m0, label %apply_z, label %skip_z
apply_z:
  call void @__quantum__qis__z__body(%Qubit* inttoptr (i64 2 to %Qubit*))
  br label %skip_z
skip_z:
  ; Measure q2
  call void @__quantum__qis__mz__body(%Qubit* inttoptr (i64 2 to %Qubit*), %Result* inttoptr (i64 2 to %Result*))

  ; Record: m0 (q0), m1 (q1), m2 (q2 after corrections)
  call void @__quantum__rt__result_record_output(%Result* null, i8* null)
  call void @__quantum__rt__result_record_output(%Result* inttoptr (i64 1 to %Result*), i8* null)
  call void @__quantum__rt__result_record_output(%Result* inttoptr (i64 2 to %Result*), i8* null)
  ret void
}

declare void @__quantum__qis__h__body(%Qubit*)
declare void @__quantum__qis__cnot__body(%Qubit*, %Qubit*)
declare void @__quantum__qis__x__body(%Qubit*)
declare void @__quantum__qis__z__body(%Qubit*)
declare void @__quantum__qis__mz__body(%Qubit*, %Result* writeonly) #1
declare i1 @__quantum__qis__read_result__body(%Result*)
declare void @__quantum__rt__result_record_output(%Result*, i8*)

attributes #0 = { "entry_point" "output_labeling_schema" "qir_profiles"="adaptive_profile" "required_num_qubits"="3" "required_num_results"="3" }
attributes #1 = { "irreversible" }

!llvm.module.flags = !{!0, !1, !2, !3}
!0 = !{i32 1, !"qir_major_version", i32 1}
!1 = !{i32 7, !"qir_minor_version", i32 0}
!2 = !{i32 1, !"dynamic_qubit_management", i1 false}
!3 = !{i32 1, !"dynamic_result_management", i1 false}
