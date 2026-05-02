; Quantum teleportation with mid-circuit measurement and conditional corrections.
; QIR Adaptive Profile, spec version 2.0.
;
; q0 = state to teleport, prepared as |+>
; q1, q2 = Bell pair
; r0, r1 = Bell measurement results
; r2 = final measurement of q2

@0 = internal constant [3 x i8] c"m0\00"
@1 = internal constant [3 x i8] c"m1\00"
@2 = internal constant [3 x i8] c"m2\00"
@3 = internal constant [13 x i8] c"teleport_out\00"

define i64 @main() #0 {
entry:
  call void @__quantum__rt__initialize(ptr null)
  br label %body

body:
  ; Prepare |+> on q0.
  tail call void @__quantum__qis__h__body(ptr null)

  ; Create a Bell pair on q1 and q2.
  tail call void @__quantum__qis__h__body(ptr inttoptr (i64 1 to ptr))
  tail call void @__quantum__qis__cnot__body(ptr inttoptr (i64 1 to ptr), ptr inttoptr (i64 2 to ptr))

  ; Bell measurement on q0 and q1.
  tail call void @__quantum__qis__cnot__body(ptr null, ptr inttoptr (i64 1 to ptr))
  tail call void @__quantum__qis__h__body(ptr null)
  tail call void @__quantum__qis__mz__body(ptr null, ptr writeonly null)
  %m0 = tail call i1 @__quantum__rt__read_result(ptr readonly null)
  tail call void @__quantum__qis__mz__body(ptr inttoptr (i64 1 to ptr), ptr writeonly inttoptr (i64 1 to ptr))
  %m1 = tail call i1 @__quantum__rt__read_result(ptr readonly inttoptr (i64 1 to ptr))

  br i1 %m1, label %apply_x, label %after_x

apply_x:
  tail call void @__quantum__qis__x__body(ptr inttoptr (i64 2 to ptr))
  br label %after_x

after_x:
  br i1 %m0, label %apply_z, label %after_z

apply_z:
  tail call void @__quantum__qis__z__body(ptr inttoptr (i64 2 to ptr))
  br label %after_z

after_z:
  tail call void @__quantum__qis__mz__body(ptr inttoptr (i64 2 to ptr), ptr writeonly inttoptr (i64 2 to ptr))
  br label %output

output:
  call void @__quantum__rt__tuple_record_output(i64 3, ptr @3)
  call void @__quantum__rt__result_record_output(ptr null, ptr @0)
  call void @__quantum__rt__result_record_output(ptr inttoptr (i64 1 to ptr), ptr @1)
  call void @__quantum__rt__result_record_output(ptr inttoptr (i64 2 to ptr), ptr @2)
  ret i64 0
}

declare void @__quantum__rt__initialize(ptr)
declare i1 @__quantum__rt__read_result(ptr readonly)
declare void @__quantum__rt__tuple_record_output(i64, ptr)
declare void @__quantum__rt__result_record_output(ptr, ptr)

declare void @__quantum__qis__h__body(ptr)
declare void @__quantum__qis__cnot__body(ptr, ptr)
declare void @__quantum__qis__x__body(ptr)
declare void @__quantum__qis__z__body(ptr)
declare void @__quantum__qis__mz__body(ptr, ptr writeonly) #1

attributes #0 = { "entry_point" "qir_profiles"="adaptive_profile" "output_labeling_schema"="schema_id" "required_num_qubits"="3" "required_num_results"="3" }
attributes #1 = { "irreversible" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!0 = !{i32 1, !"qir_major_version", i32 2}
!1 = !{i32 7, !"qir_minor_version", i32 0}
!2 = !{i32 1, !"dynamic_qubit_management", i1 false}
!3 = !{i32 1, !"dynamic_result_management", i1 false}
!4 = !{i32 1, !"ir_functions", i1 false}
!5 = !{i32 1, !"backwards_branching", i2 0}
!6 = !{i32 1, !"multiple_target_branching", i1 false}
!7 = !{i32 1, !"multiple_return_points", i1 false}
!8 = !{i32 1, !"arrays", i1 false}
