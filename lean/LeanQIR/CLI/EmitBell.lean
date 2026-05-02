import LeanQIR.Examples.Bell

def main : IO UInt32 := do
  match bellLL with
  | .ok llvm =>
      IO.print llvm
      pure 0
  | .error message =>
      IO.eprintln message
      pure 1
