# Package

version     = "1.0.0"
author      = "Dennis Felsing; narimiran"
description = "Arbitrary-precision integers implemented in pure Nim"
license     = "MIT"

srcDir      = "src"

# Dependencies

requires "nim >= 1.4.0"

task test, "Test bigints":
  for backend in ["c", "cpp"]:
    echo "testing " & backend & " backend"
    for gc in ["refc", "arc", "orc"]:
      echo "  using " & gc & " GC"
      for file in ["tbigints.nim", "tbugs.nim"]:
        exec "nim r --hints:off --experimental:strictFuncs --backend:" & backend & " --gc:" & gc & " tests/" & file
      exec "nim doc --hints:off --backend:" & backend & " --gc:" & gc & " src/bigints.nim"

task checkExamples, "Check examples":
  echo "checking examples"
  for example in listFiles("examples"):
    if example.endsWith(".nim"):
      exec "nim check --hints:off " & example
