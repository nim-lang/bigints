# Bigint type definition and initBigInt overloaded functions
import std/bitops

type
  BigInt* = object
    ## An arbitrary precision integer.
    # Invariants for `a: BigInt`:
    # * if `a` is non-zero: `a.limbs[a.limbs.high] != 0`
    # * if `a` is zero: `a.limbs.len <= 1`
    limbs: seq[uint32]
    isNegative: bool


func normalize(a: var BigInt) =
  for i in countdown(a.limbs.high, 0):
    if a.limbs[i] > 0'u32:
      a.limbs.setLen(i+1)
      return
  a.limbs.setLen(1)

func initBigInt*(vals: sink seq[uint32], isNegative = false): BigInt =
  ## Initializes a `BigInt` from a sequence of `uint32` values.
  runnableExamples:
    let a = @[10'u32, 2'u32].initBigInt
    let b = 10 + 2 shl 32
    assert $a == $b
  result.limbs = vals
  result.isNegative = isNegative
  normalize(result)

func initBigInt*[T: int8|int16|int32](val: T): BigInt =
  if val < 0:
    result.limbs = @[(not val).uint32 + 1] # manual 2's complement (to avoid overflow)
    result.isNegative = true
  else:
    result.limbs = @[val.uint32]
    result.isNegative = false

func initBigInt*[T: uint8|uint16|uint32](val: T): BigInt =
  result.limbs = @[val.uint32]

func initBigInt*(val: int64): BigInt =
  var a = val.uint64
  if val < 0:
    a = not a + 1 # 2's complement
    result.isNegative = true
  if a > uint32.high:
    result.limbs = @[(a and uint32.high).uint32, (a shr 32).uint32]
  else:
    result.limbs = @[a.uint32]

func initBigInt*(val: uint64): BigInt =
  if val > uint32.high:
    result.limbs = @[(val and uint32.high).uint32, (val shr 32).uint32]
  else:
    result.limbs = @[val.uint32]

when sizeof(int) == 4:
  template initBigInt*(val: int): BigInt = initBigInt(val.int32)
  template initBigInt*(val: uint): BigInt = initBigInt(val.uint32)
else:
  template initBigInt*(val: int): BigInt = initBigInt(val.int64)
  template initBigInt*(val: uint): BigInt = initBigInt(val.uint64)

func initBigInt*(val: BigInt): BigInt =
  result = val

func reset(a: var BigInt) =
  ## Resets a `BigInt` back to the zero value.
  a.limbs.setLen(1)
  a.limbs[0] = 0
  a.isNegative = false

func countTrailingZeroBits(a: BigInt): int =
  var count = 0
  for x in a.limbs:
    if x == 0:
      count += 32
    else:
      return count + countTrailingZeroBits(x)
  return count

const
  zero = initBigInt(0)
  one = initBigInt(1)

func isZero(a: BigInt): bool {.inline.} =
  a.limbs.len == 0 or (a.limbs.len == 1 and a.limbs[0] == 0)

func fastLog2*(a: BigInt): int =
  ## Computes the logarithm in base 2 of `a`.
  ## If `a` is negative, returns the logarithm of `abs(a)`.
  ## If `a` is zero, returns -1.
  if a.isZero:
    return -1
  bitops.fastLog2(a.limbs[^1]) + 32*(a.limbs.high)

