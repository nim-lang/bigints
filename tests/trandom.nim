import bigints
import random

type
  MemSizeUnit = enum
    o, Kio, Mio, Gio

const
  zero = initBigInt(0)
  one = initBigInt(1)
  memSize = 2 # Max number of allocated memory for the tests
  memSizeUnit = Mio # Unit in which memSize is expressed

proc computeLimit(memSize: Natural, memSizeUnit: MemSizeUnit): Natural =
  result = memSize
  for _ in 1..ord(memSizeUnit):
    result *= 1024

const
  memLimit = computeLimit(memSize, memSizeUnit) # Number of octets
  maxLimbs = memLimit div 8
  maxBits = 4*memLimit

proc main() =
  randomize()

  block:
    let a: BigInt = initRandomBigInt(0, Bits)
    doAssert a == zero
    let b: BigInt = initRandomBigInt(1, Bits)
    doAssert b == one

  block:
    for nBits in [29, 32, 1037]:
      for _ in 1 .. 5: # Repeat probabilistic tests
        let a: BigInt = initRandomBigInt(nBits, Bits)
        doAssert fastLog2(a) == (nBits - 1)
        doAssert (toString(a, 2)).len == nBits
    # For bigger bigints, remove the test with slow conversion to string
    for nBits in [rand(1..maxBits), 32*rand(1..maxLimbs)]:
      for _ in 1 .. 5:
        let a: BigInt = initRandomBigInt(nBits, Bits)
        doAssert fastLog2(a) == (nBits - 1)

  block:
    for nLimbs in [1, 2, 3, 5, 10, 25, 100]:
      for _ in 1 .. 5:
        let a: BigInt = initRandomBigInt(nLimbs)
        let n_bitsA = fastLog2(a) + 1
        doAssert n_bitsA <= 32*nlimbs
        doAssert n_bitsA > 32*(nlimbs-1)

  block: # GCD properties but tested on random Bigints
    let limitGCD = 100_000 # Special limit for the GCD, otherwise the tests run for hours
    let (nBitsA, nBitsB, nBitsC) = (rand(1..limitGCD), rand(1..limitGCD), rand(1..limitGCD))
    let a = initRandomBigInt(nBitsA, Bits)
    let b = initRandomBigInt(nBitsB, Bits)
    let c = initRandomBigInt(nBitsC, Bits)
    doAssert gcd(a, b) == gcd(b, a)
    doAssert gcd(a, zero) == a
    doAssert gcd(a, a) == a
    doAssert gcd(c * a, c * b) == c * gcd(a,b)
    doAssert gcd(a, gcd(b, c)) == gcd(gcd(a, b), c)
    doAssert gcd(a, b) == gcd(b, a mod b)

main()
