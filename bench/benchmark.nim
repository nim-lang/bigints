import os, criterion, bigints

var cfg = newDefaultConfig()

cfg.verbose = true

let params = commandLineParams()
if params.len == 1:
  cfg.outputPath = params[0]
else:
  cfg.outputPath = "bench/benchmark.json"

# benchmark taken from:
# https://github.com/peterolson/BigInteger.js/blob/f6b6e951d06fb90b863cda9e6a39ed01ebb1f537/benchmark/tests.js
# see also: https://peterolson.github.io/BigInteger.js/benchmark/
benchmark cfg:
  const
    a = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
    b = "1234567890234567890134567890124567890123567890123467890123457890123456890123456790123456780123456789"
    c = "98109840984098409156481068456541684065964819841065106865710397464513210416435401645030648036034063974065004951094209420942097421970490274195049120974210974209742190274092740492097420929892490974202241"
    d = c & c & c & c & c & c & c & c & c & c
    e = d & d & d & d & d & d & d & d & d & d
    f = e & e & e
    c2 = a & b
    d2 = c2 & c2 & c2 & c2 & c2 & c2 & c2 & c2 & c2 & c2
    e2 = d2 & d2 & d2 & d2 & d2 & d2 & d2 & d2 & d2 & d2
    f2 = e2 & e2 & e2
    s1 = 12345
    s2 = 98765
    s3 = 5437654
    five = 5
    twentytwo = 22
    twentythree = 23
  let
    large1 = a.initBigInt # 100 digits
    large2 = b.initBigInt # 100 digits
    small1 = s1.initBigInt # 5 digits
    small2 = s2.initBigInt # 5 digits
    small3 = s3.initBigInt # 7 digits
    medium1 = "9876543210".initBigInt # 10 digits (and bigger than uint32.high)
    medium2 = "8967452301".initBigInt # 10 digits (and bigger than uint32.high)
    num200digits1 = c.initBigInt
    num200digits2 = c2.initBigInt
    num2kdigits1 = d.initBigInt
    num2kdigits2 = d2.initBigInt
    num20kdigits1 = e.initBigInt
    num20kdigits2 = e2.initBigInt
    num60kdigits1 = f.initBigInt
    num60kdigits2 = f2.initBigInt
  
  let
    addBenchParams = [
      ("100d", large1, large2)
    ]

  proc addition(name: string; x, y: BigInt) {.measure: addBenchParams.} =
    discard x + y

  let
    chainedAddBenchParams = [
      ("100d,3i", large1, large2, 3), # equivalent to 10 additions
      ("100d,33i", large1, large2, 33) # equivalent to 100 additions
    ]
  proc chainedAddition(name: string; a, b: BigInt, iter: int) {.measure: chainedAddBenchParams.} =
    var
      a = a
      b = b
      c = a + b
    for i in 1 .. iter:
      a = b + c
      b = a + c
      c = a + b

  let
    mulBenchParams = [
      ("100d", large1, large2)
    ]

  proc multiplication(name: string; x, y: BigInt) {.measure: mulBenchParams.} =
    discard x * y

  let
    chainedMulBenchParams = [
      ("10d,3i", medium1, medium2, 3)  # equivalent to 10 multiplications
      #,("100d,3i", large1, large2, 3)
    ]
  proc chainedMultiplication(name: string; a, b: BigInt, iter: int) {.measure: chainedMulBenchParams.} =
    var
      a = a
      b = b
      c = a * b
    for i in 1 .. iter:
      a = b * c
      b = a * c
      c = a * b
