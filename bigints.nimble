# Package

version     = "1.0.0"
author      = "Dennis Felsing; narimiran"
description = "Arbitrary-precision integers implemented in pure Nim"
license     = "MIT"

srcDir      = "src"

# Dependencies

requires "nim >= 1.4.0"

task test, "Test bigints":
  exec "nim r --backend:c tests/tbigints.nim"
  exec "nim r --backend:c tests/tbugs.nim"
  exec "nim r --backend:cpp tests/tbigints.nim"
  exec "nim r --backend:cpp tests/tbugs.nim"
