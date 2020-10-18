# Package

version     = "0.4.5"
author      = "Dennis Felsing"
description = "Arbitrary-precision integers implemented in pure Nim"
license     = "MIT"

srcDir      = "src"

# Dependencies

requires "nim > 0.10"

task tests, "Test bigints":
  exec "nim c -r tests/tester"

task test27, "test separately issue 27":  # cleanup: remove this at the end? or should we keep it anyway (maybe in tests task when passing)
  exec "nim c -r tests/tissue_27"
