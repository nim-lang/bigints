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
  exec "nim c -r tests/tissue_27"

task bench, "Benchmark bigints":
  withDir("bench"):
    exec "nim c -r -d:release benchmark benchmark.json"
    exec "nim c -r -d:release -d:bigintsUseOldSetXLen benchmark benchmark_oldSetXLen.json"
    exec "nim c -r -d:release report benchmark.json benchmark_oldSetXLen.json benchmark.md"