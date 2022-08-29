# shl, shr, and bitwise logical operators: and, or, not
include arithmeticOperators

func `shl`*(x: BigInt, y: Natural): BigInt =
  ## Shifts a `BigInt` to the left.
  runnableExamples:
    let a = 24.initBigInt
    assert a shl 1 == 48.initBigInt
    assert a shl 2 == 96.initBigInt

  var carry = 0'u64
  let a = y div 32
  let b = uint32(y mod 32)
  let mask = ((1'u64 shl b) - 1) shl (64 - b)
  result.limbs.setLen(x.limbs.len + a)
  result.isNegative = x.isNegative

  for i in countup(0, x.limbs.high):
    let acc = (uint64(x.limbs[i]) shl 32) or carry
    carry = (acc and mask) shr 32
    result.limbs[i + a] = uint32((acc shl b) shr 32)

  if carry > 0:
    result.limbs.add(uint32(carry shr (32 - b)))

# forward declaration for use in `shr`
func dec*(a: var BigInt, b: int = 1)

func `shr`*(x: BigInt, y: Natural): BigInt =
  ## Shifts a `BigInt` to the right (arithmetically).
  runnableExamples:
    let a = 24.initBigInt
    assert a shr 1 == 12.initBigInt
    assert a shr 2 == 6.initBigInt

  var carry = 0'u64
  let a = y div 32
  let b = uint32(y mod 32)
  let mask = (1'u32 shl b) - 1
  result.limbs.setLen(x.limbs.len - a)
  result.isNegative = x.isNegative

  for i in countdown(x.limbs.high, a):
    let acc = (carry shl 32) or x.limbs[i]
    carry = acc and mask
    result.limbs[i - a] = uint32(acc shr b)

  if result.isNegative:
    var underflow = false
    if carry > 0:
      underflow = true
    else:
      for i in 0 .. a - 1:
        if x.limbs[i] > 0:
          underflow = true
          break

    if underflow:
      dec result

  if result.limbs.len > 1 and result.limbs[result.limbs.high] == 0:
    # normalize
    result.limbs.setLen(result.limbs.high)

func bitwiseAnd(a: var BigInt, b, c: BigInt) =
  a.limbs.setLen(min(b.limbs.len, c.limbs.len))
  for i in 0 ..< a.limbs.len:
    a.limbs[i] = b.limbs[i] and c.limbs[i]

func `and`*(a, b: BigInt): BigInt =
  ## Bitwise `and` for `BigInt`s.
  assert (not a.isNegative) and (not b.isNegative)
  bitwiseAnd(result, a, b)
  normalize(result)

func bitwiseOr(a: var BigInt, b, c: BigInt) =
  # `b` must be smaller than `c`
  a.limbs.setLen(c.limbs.len)
  for i in 0 ..< b.limbs.len:
    a.limbs[i] = b.limbs[i] or c.limbs[i]
  for i in b.limbs.len ..< c.limbs.len:
    a.limbs[i] = c.limbs[i]

func `or`*(a, b: BigInt): BigInt =
  ## Bitwise `or` for `BigInt`s.
  assert (not a.isNegative) and (not b.isNegative)
  if a.limbs.len <= b.limbs.len:
    bitwiseOr(result, a, b)
  else:
    bitwiseOr(result, b, a)

func bitwiseXor(a: var BigInt, b, c: BigInt) =
  # `b` must be smaller than `c`
  a.limbs.setLen(c.limbs.len)
  for i in 0 ..< b.limbs.len:
    a.limbs[i] = b.limbs[i] xor c.limbs[i]
  for i in b.limbs.len ..< c.limbs.len:
    a.limbs[i] = c.limbs[i]

func `xor`*(a, b: BigInt): BigInt =
  ## Bitwise `xor` for `BigInt`s.
  assert (not a.isNegative) and (not b.isNegative)
  if a.limbs.len <= b.limbs.len:
    bitwiseXor(result, a, b)
  else:
    bitwiseXor(result, b, a)
  normalize(result)
