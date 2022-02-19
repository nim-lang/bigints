## Arbitrary precision integers.

import std/[algorithm, bitops, math, options]

type
  BigInt* = object
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

const
  zero = initBigInt(0)
  one = initBigInt(1)

func isZero(a: BigInt): bool {.inline.} =
  for i in countdown(a.limbs.high, 0):
    if a.limbs[i] != 0'u32:
      return false
  return true

func abs*(a: BigInt): BigInt =
  # Returns the absolute value of `a`.
  runnableExamples:
    assert abs(42.initBigInt) == 42.initBigInt
    assert abs(-12.initBigInt) == 12.initBigInt
  result = a
  result.isNegative = false

func unsignedCmp(a: BigInt, b: uint32): int64 =
  # ignores the sign of `a`
  # `a` and `b` are assumed to not be zero
  result = int64(a.limbs.len) - 1
  if result != 0: return
  result = int64(a.limbs[0]) - int64(b)

func unsignedCmp(a: uint32, b: BigInt): int64 = -unsignedCmp(b, a)

func unsignedCmp(a, b: BigInt): int64 =
  # ignores the signs of `a` and `b`
  # `a` and `b` are assumed to not be zero
  result = int64(a.limbs.len) - int64(b.limbs.len)
  if result != 0: return
  for i in countdown(a.limbs.high, 0):
    result = int64(a.limbs[i]) - int64(b.limbs[i])
    if result != 0:
      return

func cmp(a, b: BigInt): int64 =
  ## Returns:
  ## * a value less than zero, if `a < b`
  ## * a value greater than zero, if `a > b`
  ## * zero, if `a == b`
  if a.isZero:
    if b.isZero:
      return 0
    elif b.isNegative:
      return 1
    else:
      return -1
  elif a.isNegative:
    if b.isZero or not b.isNegative:
      return -1
    else:
      return unsignedCmp(b, a)
  else: # a > 0
    if b.isZero or b.isNegative:
      return 1
    else:
      return unsignedCmp(a, b)

func cmp(a: BigInt, b: int32): int64 =
  ## Returns:
  ## * a value less than zero, if `a < b`
  ## * a value greater than zero, if `a > b`
  ## * zero, if `a == b`
  if a.isZero:
    return -b.int64
  elif a.isNegative:
    if b < 0:
      return unsignedCmp((not b).uint32 + 1, a)
    else:
      return -1
  else: # a > 0
    if b <= 0:
      return 1
    else:
      return unsignedCmp(a, b.uint32)

func cmp(a: int32, b: BigInt): int64 = -cmp(b, a)

func `==`*(a, b: BigInt): bool =
  ## Compares if two `BigInt` numbers are equal.
  runnableExamples:
    let
      a = 5.initBigInt
      b = 3.initBigInt
      c = 2.initBigInt
    assert a == b + c
    assert b != c
  cmp(a, b) == 0

func `<`*(a, b: BigInt): bool =
  runnableExamples:
    let
      a = 5.initBigInt
      b = 3.initBigInt
      c = 2.initBigInt
    assert b < a
    assert b > c
  cmp(a, b) < 0

func `<=`*(a, b: BigInt): bool =
  runnableExamples:
    let
      a = 5.initBigInt
      b = 3.initBigInt
      c = 2.initBigInt
    assert a <= b + c
    assert c <= b
  cmp(a, b) <= 0

func `==`(a: BigInt, b: int32): bool = cmp(a, b) == 0
func `<`(a: BigInt, b: int32): bool = cmp(a, b) < 0
func `<`(a: int32, b: BigInt): bool = cmp(a, b) < 0

template addParts(toAdd) =
  tmp += toAdd
  a.limbs[i] = uint32(tmp and uint32.high)
  tmp = tmp shr 32

func unsignedAdditionInt(a: var BigInt, b: BigInt, c: uint32) =
  let bl = b.limbs.len
  a.limbs.setLen(bl)

  var tmp: uint64 = uint64(c)
  for i in 0 ..< bl:
    addParts(uint64(b.limbs[i]))
  if tmp > 0'u64:
    a.limbs.add(uint32(tmp))
  a.isNegative = false

func unsignedAddition(a: var BigInt, b, c: BigInt) =
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var m = min(bl, cl)
  a.limbs.setLen(max(bl, cl))

  var tmp = 0'u64
  for i in 0 ..< m:
    addParts(uint64(b.limbs[i]) + uint64(c.limbs[i]))
  if bl < cl:
    for i in m ..< cl:
      addParts(uint64(c.limbs[i]))
  else:
    for i in m ..< bl:
      addParts(uint64(b.limbs[i]))
  if tmp > 0'u64:
    a.limbs.add(uint32(tmp))
  a.isNegative = false

func negate(a: var BigInt) =
  a.isNegative = not a.isNegative

func `-`*(a: BigInt): BigInt =
  ## Unary minus for `BigInt`.
  runnableExamples:
    let
      a = 5.initBigInt
      b = -10.initBigInt
    assert (-a) == -5.initBigInt
    assert (-b) == 10.initBigInt
  result = a
  negate(result)

template realUnsignedSubtractionInt(a: var BigInt, b: BigInt, c: uint32) =
  # b > c
  let bl = b.limbs.len
  a.limbs.setLen(bl)

  var tmp = int64(c)
  for i in 0 ..< bl:
    tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - tmp
    a.limbs[i] = uint32(tmp and int64(uint32.high))
    tmp = 1 - (tmp shr 32)
  a.isNegative = false

  normalize(a)
  assert tmp == 0

template realUnsignedSubtraction(a: var BigInt, b, c: BigInt) =
  # b > c
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var m = min(bl, cl)
  a.limbs.setLen(max(bl, cl))

  var tmp = 0'i64
  for i in 0 ..< m:
    tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - int64(c.limbs[i]) - tmp
    a.limbs[i] = uint32(tmp and int64(uint32.high))
    tmp = 1 - (tmp shr 32)
  if bl < cl:
    for i in m ..< cl:
      tmp = int64(uint32.high) + 1 - int64(c.limbs[i]) - tmp
      a.limbs[i] = uint32(tmp and int64(uint32.high))
      tmp = 1 - (tmp shr 32)
    a.isNegative = true
  else:
    for i in m ..< bl:
      tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - tmp
      a.limbs[i] = uint32(tmp and int64(uint32.high))
      tmp = 1 - (tmp shr 32)
    a.isNegative = false

  normalize(a)
  assert tmp == 0

func unsignedSubtractionInt(a: var BigInt, b: BigInt, c: uint32) =
  # `b` is not zero
  let cmpRes = unsignedCmp(b, c)
  if cmpRes > 0:
    realUnsignedSubtractionInt(a, b, c)
  elif cmpRes < 0:
    # `b` is only a single limb
    a.limbs = @[c - b.limbs[0]]
    a.isNegative = true
  else: # b == c
    a = zero

func unsignedSubtraction(a: var BigInt, b, c: BigInt) =
  let cmpRes = unsignedCmp(b, c)
  if cmpRes > 0:
    realUnsignedSubtraction(a, b, c)
  elif cmpRes < 0:
    realUnsignedSubtraction(a, c, b)
    a.negate()
  else: # b == c
    a = zero

func additionInt(a: var BigInt, b: BigInt, c: int32) =
  # a = b + c
  if b.isZero:
    a = c.initBigInt
  elif b.isNegative:
    if c < 0:
      unsignedAdditionInt(a, b, (not c).uint32 + 1)
    else:
      unsignedSubtractionInt(a, b, c.uint32)
    a.negate()
  else:
    if c < 0:
      unsignedSubtractionInt(a, b, (not c).uint32 + 1)
    else:
      unsignedAdditionInt(a, b, c.uint32)

func addition(a: var BigInt, b, c: BigInt) =
  # a = b + c
  if b.isNegative:
    if c.isNegative:
      unsignedAddition(a, b, c)
      a.isNegative = true
    else:
      unsignedSubtraction(a, c, b)
  else:
    if c.isNegative:
      unsignedSubtraction(a, b, c)
    else:
      unsignedAddition(a, b, c)

func `+`*(a, b: BigInt): BigInt =
  ## Addition for `BigInt`s.
  runnableExamples:
    let
      a = 5.initBigInt
      b = 10.initBigInt
    assert a + b == 15.initBigInt
    assert (-a) + b == 5.initBigInt
    assert a + (-b) == -5.initBigInt
  addition(result, a, b)

template `+=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 5.initBigInt
    a += 2.initBigInt
    assert a == 7.initBigInt
  a = a + b

func subtractionInt(a: var BigInt, b: BigInt, c: int32) =
  # a = b - c
  if b.isZero:
    a = -c.initBigInt
  elif b.isNegative:
    if c < 0:
      unsignedSubtractionInt(a, b, (not c).uint32 + 1)
    else:
      unsignedAdditionInt(a, b, c.uint32)
    a.negate()
  else:
    if c < 0:
      unsignedAdditionInt(a, b, (not c).uint32 + 1)
    else:
      unsignedSubtractionInt(a, b, c.uint32)

func subtraction(a: var BigInt, b, c: BigInt) =
  # a = b - c
  if b.isNegative:
    if c.isNegative:
      unsignedSubtraction(a, c, b)
    else:
      unsignedAddition(a, b, c)
      a.isNegative = true
  else:
    if c.isNegative:
      unsignedAddition(a, b, c)
    else:
      unsignedSubtraction(a, b, c)

func `-`*(a, b: BigInt): BigInt =
  ## Subtraction for `BigInt`s.
  runnableExamples:
    let
      a = 15.initBigInt
      b = 10.initBigInt
    assert a - b == 5.initBigInt
    assert (-a) - b == -25.initBigInt
    assert a - (-b) == 25.initBigInt
  subtraction(result, a, b)

template `-=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 5.initBigInt
    a -= 2.initBigInt
    assert a == 3.initBigInt
  a = a - b


func unsignedMultiplication(a: var BigInt, b, c: BigInt) {.inline.} =
  # always called with bl >= cl
  let
    bl = b.limbs.len
    cl = c.limbs.len
  a.limbs.setLen(bl + cl)
  var tmp = 0'u64

  for i in 0 ..< bl:
    tmp += uint64(b.limbs[i]) * uint64(c.limbs[0])
    a.limbs[i] = uint32(tmp and uint32.high)
    tmp = tmp shr 32

  a.limbs[bl] = uint32(tmp)

  for j in 1 ..< cl:
    tmp = 0'u64
    for i in 0 ..< bl:
      tmp += uint64(a.limbs[j + i]) + uint64(b.limbs[i]) * uint64(c.limbs[j])
      a.limbs[j + i] = uint32(tmp and uint32.high)
      tmp = tmp shr 32
    var pos = j + bl
    while tmp > 0'u64:
      tmp += uint64(a.limbs[pos])
      a.limbs[pos] = uint32(tmp and uint32.high)
      tmp = tmp shr 32
      inc pos
  normalize(a)

func multiplication(a: var BigInt, b, c: BigInt) =
  # a = b * c
  if b.isZero or c.isZero:
    a = zero
    return
  let
    bl = b.limbs.len
    cl = c.limbs.len

  if cl > bl:
    unsignedMultiplication(a, c, b)
  else:
    unsignedMultiplication(a, b, c)
  a.isNegative = b.isNegative xor c.isNegative

func `*`*(a, b: BigInt): BigInt =
  ## Multiplication for `BigInt`s.
  runnableExamples:
    let
      a = 421.initBigInt
      b = 200.initBigInt
    assert a * b == 84200.initBigInt
  multiplication(result, a, b)

template `*=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 15.initBigInt
    a *= 10.initBigInt
    assert a == 150.initBigInt
  a = a * b

func pow*(x: BigInt, y: Natural): BigInt =
  ## Computes `x` to the power of `y`.
  var base = x
  var exp = y
  result = one

  # binary exponentiation
  while exp > 0:
    if (exp and 1) > 0:
      result *= base
    exp = exp shr 1
    base *= base

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

func reset(a: var BigInt) =
  ## Resets a `BigInt` back to the zero value.
  a.limbs.setLen(1)
  a.limbs[0] = 0
  a.isNegative = false

func unsignedDivRem(q: var BigInt, r: var uint32, n: BigInt, d: uint32) =
  q.limbs.setLen(n.limbs.len)
  r = 0
  for i in countdown(n.limbs.high, 0):
    let tmp = uint64(n.limbs[i]) + uint64(r) shl 32
    q.limbs[i] = uint32(tmp div d)
    r = uint32(tmp mod d)
  normalize(q)

func bits(d: uint32): int =
  const bitLengths = [0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4,
                      5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]
  var d = d
  while d >= 32'u32:
    result += 6
    d = d shr 6
  result += bitLengths[int(d)]

# From Knuth and Python
func unsignedDivRem(q, r: var BigInt, n, d: BigInt) =
  var
    nn = n.limbs.len
    dn = d.limbs.len

  if n.isZero:
    q = zero
    r = zero
  elif nn < dn:
    # n < d
    q = zero
    r = n
  elif dn == 1:
    var x: uint32
    unsignedDivRem(q, x, n, d.limbs[0])
    r.limbs = @[x]
    r.isNegative = false
  else:
    assert nn >= dn and dn >= 2

    # normalize
    let ls = 32 - bits(d.limbs[d.limbs.high])
    r = d shl ls
    q = n shl ls
    if q.limbs.len > n.limbs.len or q.limbs[q.limbs.high] >= r.limbs[r.limbs.high]:
      q.limbs.add(0'u32)
      inc(nn)

    let k = nn - dn
    assert k >= 0
    var a: BigInt
    a.limbs.setLen(k)
    let wm1 = r.limbs[r.limbs.high]
    let wm2 = r.limbs[r.limbs.high-1]
    var ak = k

    var zhi = zero
    var z = zero
    var qib = zero
    var q1b = zero

    for v in countdown(k-1, 0):
      # estimate quotient digit, may rarely overestimate by 1
      let vtop = q.limbs[v + dn]
      assert vtop <= wm1
      let vv = (uint64(vtop) shl 32) or q.limbs[v+dn-1]
      var q1 = vv div wm1
      var r1 = vv mod wm1

      while (wm2 * q1) > ((r1 shl 32) or q.limbs[v+dn-2]):
        dec q1
        r1 += wm1
        if r1 > uint32.high:
          break

      assert q1 <= uint32.high

      q1b.limbs[0] = uint32(q1)

      # subtract
      zhi.reset()
      for i in 0 ..< dn:
        z.reset()
        z.limbs[0] = r.limbs[i]
        z *= q1b
        z.isNegative = true
        z += zhi
        var z1 = z
        qib.limbs[0] = q.limbs[v+i]
        z += qib

        if z < 0:
          q.limbs[v+i] = not z.limbs[0] + 1
        else:
          q.limbs[v+i] = z.limbs[0]

        if z.limbs.len > 1:
          zhi.limbs[0] = z1.limbs[1]
          if z1.limbs[0] > qib.limbs[0]:
            zhi.limbs[0] += 1
          zhi.isNegative = true
        elif z < 0:
          zhi.limbs[0] = 1
          zhi.isNegative = true
        else:
          zhi.reset()

      # add back if was too large (rare branch)
      if vtop.initBigInt + zhi < 0:
        var carry = 0'u64
        for i in 0 ..< dn:
          carry += q.limbs[v+i]
          carry += r.limbs[i]
          q.limbs[v+i] = uint32(carry and uint32.high)
          carry = carry shr 32
        dec(q1)

      # store quotient digit
      assert q1 <= uint32.high
      dec(ak)
      a.limbs[ak] = uint32(q1)

    # unshift remainder, we reuse w1 to store the result
    q.limbs.setLen(dn)
    r = q shr ls

    normalize(r)
    q = a
    normalize(q)

func division(q, r: var BigInt, n, d: BigInt) =
  # q = n div d
  # r = n mod d
  if d.isZero:
    raise newException(DivByZeroDefect, "division by zero")

  unsignedDivRem(q, r, n, d)

  q.isNegative = n < 0 xor d < 0
  r.isNegative = n < 0 and r != 0

  # divrem -> divmod
  if (r < 0 and d > 0) or (r > 0 and d < 0):
    r += d
    q -= one

func `div`*(a, b: BigInt): BigInt =
  ## Computes the integer division of two `BigInt` numbers.
  ## Raises a `DivByZeroDefect` if `b` is zero.
  ##
  ## If you also need the modulo (remainder), use the `divmod func <#divmod,BigInt,BigInt>`_.
  runnableExamples:
    let
      a = 17.initBigInt
      b = 5.initBigInt
    assert a div b == 3.initBigInt
    assert (-a) div b == -4.initBigInt
    assert a div (-b) == -4.initBigInt
    assert (-a) div (-b) == 3.initBigInt
  var tmp: BigInt
  division(result, tmp, a, b)

func `mod`*(a, b: BigInt): BigInt =
  ## Computes the integer modulo (remainder) of two `BigInt` numbers.
  ## Raises a `DivByZeroDefect` if `b` is zero.
  ##
  ## If you also need an integer division, use the `divmod func <#divmod,BigInt,BigInt>`_.
  runnableExamples:
    let
      a = 17.initBigInt
      b = 5.initBigInt
    assert a mod b == 2.initBigInt
    assert (-a) mod b == 3.initBigInt
    assert a mod (-b) == -3.initBigInt
    assert (-a) mod (-b) == -2.initBigInt
  var tmp: BigInt
  division(tmp, result, a, b)

func divmod*(a, b: BigInt): tuple[q, r: BigInt] =
  ## Computes both the integer division and modulo (remainder) of two
  ## `BigInt` numbers.
  ## Raises a `DivByZeroDefect` if `b` is zero.
  runnableExamples:
    let
      a = 17.initBigInt
      b = 5.initBigInt
    assert divmod(a, b) == (3.initBigInt, 2.initBigInt)
  division(result.q, result.r, a, b)

func countTrailingZeroBits(a: BigInt): int =
  var count = 0
  for x in a.limbs:
    if x == 0:
      count += 32
    else:
      return count + countTrailingZeroBits(x)
  return count

func gcd*(a, b: BigInt): BigInt =
  ## Returns the greatest common divisor (GCD) of `a` and `b`.
  runnableExamples:
    assert gcd(54.initBigInt, 24.initBigInt) == 6.initBigInt

  # binary GCD algorithm
  var
    u = abs(a)
    v = abs(b)
  if u.isZero:
    return v
  elif v.isZero:
    return u
  let
    i = countTrailingZeroBits(u)
    j = countTrailingZeroBits(v)
    k = min(i, j)
  u = u shr i
  v = v shr j
  while true:
    # u and v are odd
    if u > v:
      swap(u, v)
    v -= u
    if v.isZero:
      return u shl k
    v = v shr countTrailingZeroBits(v)


func toInt*[T: SomeInteger](x: BigInt): Option[T] =
  ## Converts a `BigInt` number to an integer, if possible.
  ## If the `BigInt` doesn't fit in a `T`, returns `none(T)`;
  ## otherwise returns `some(x)`.
  runnableExamples:
    import std/options
    let
      a = 44.initBigInt
      b = 130.initBigInt
    assert toInt[int8](a) == some(44'i8)
    assert toInt[int8](b) == none(int8)
    assert toInt[uint8](b) == some(130'u8)
    assert toInt[int](b) == some(130)

  if x.isZero:
    return some(default(T)) # default(T) is 0
  when T is SomeSignedInt:
    # T is signed
    when sizeof(T) == 8:
      if x.limbs.len > 2:
        result = none(T)
      elif x.limbs.len == 2:
        if x.isNegative:
          if x.limbs[1] > uint32(int32.high) + 1 or (x.limbs[1] == uint32(int32.high) + 1 and x.limbs[0] > 0):
            result = none(T)
          else:
            let value = not T(x.limbs[1].uint64 shl 32 + x.limbs[0] - 1)
            result = some(value)
        else:
          if x.limbs[1] > uint32(int32.high):
            result = none(T)
          else:
            let value = T(x.limbs[1].uint64 shl 32 + x.limbs[0])
            result = some(value)
      else:
        if x.isNegative:
          result = some(not T(x.limbs[0] - 1))
        else:
          result = some(T(x.limbs[0]))
    else:
      if x.limbs.len > 1:
        result = none(T)
      else:
        if x.isNegative:
          if x.limbs[0] > uint32(T.high) + 1:
            result = none(T)
          else:
            result = some(not T(x.limbs[0] - 1))
        else:
          if x.limbs[0] > uint32(T.high):
            result = none(T)
          else:
            result = some(T(x.limbs[0]))
  else:
    # T is unsigned
    if x.isNegative:
      return none(T)
    when sizeof(T) == 8:
      if x.limbs.len > 2:
        result = none(T)
      elif x.limbs.len == 2:
        let value = T(x.limbs[1]) shl 32 + T(x.limbs[0])
        result = some(value)
      else:
        result = some(T(x.limbs[0]))
    else:
      if x.limbs.len > 1:
        result = none(T)
      elif x.limbs[0] > uint32(T.high):
        result = none(T)
      else:
        result = some(T(x.limbs[0]))

func calcSizes(): array[2..36, int] =
  for i in 2..36:
    var x = int64(i)
    while x <= int64(uint32.high) + 1:
      x *= i
      result[i].inc

const
  digits = "0123456789abcdefghijklmnopqrstuvwxyz"
  powers = {2, 4, 8, 16, 32}
  sizes = calcSizes() # `sizes[base]` is the maximum number of digits that fully fit in a `uint32`

func toString*(a: BigInt, base: range[2..36] = 10): string =
  ## Produces a string representation of a `BigInt` in a specified
  ## `base`.
  ##
  ## Doesn't produce any prefixes (`0x`, `0b`, etc.).
  runnableExamples:
    let a = 55.initBigInt
    assert toString(a) == "55"
    assert toString(a, 2) == "110111"
    assert toString(a, 16) == "37"

  if a.isZero:
    return "0"

  let size = sizes[base]
  if base in powers:
    let
      bits = countTrailingZeroBits(base) # bits per digit
      mask = (1'u32 shl bits) - 1
      totalBits = 32 * a.limbs.len - countLeadingZeroBits(a.limbs[a.limbs.high])
    result = newStringOfCap((totalBits + bits - 1) div bits + 1)

    var
      acc = 0'u32
      accBits = 0 # the number of bits needed for acc
    for x in a.limbs:
      acc = acc or (x shl accBits)
      accBits += 32
      while accBits >= bits:
        result.add(digits[acc and mask])
        acc = acc shr bits
        if accBits > 32:
          acc = x shr (32 - (accBits - bits))
        accBits -= bits
    if acc > 0:
      result.add(digits[acc])
  else:
    let
      base = uint32(base)
      d = base ^ size
    var tmp = a

    tmp.isNegative = false
    result = newStringOfCap(size * a.limbs.len + 1) # estimate the length of the result

    while tmp > 0:
      var
        c: uint32
        tmpCopy = tmp
      unsignedDivRem(tmp, c, tmpCopy, d)
      for i in 1..size:
        result.add(digits[c mod base])
        c = c div base

  # normalize
  var i = result.high
  while i > 0 and result[i] == '0':
    dec i
  result.setLen(i+1)

  if a.isNegative:
    result.add('-')

  result.reverse()

func `$`*(a: BigInt): string =
  ## String representation of a `BigInt` in base 10.
  toString(a, 10)

func parseDigit(c: char, base: uint32): uint32 {.inline.} =
  result = case c
    of '0'..'9': uint32(ord(c) - ord('0'))
    of 'a'..'z': uint32(ord(c) - ord('a') + 10)
    of 'A'..'Z': uint32(ord(c) - ord('A') + 10)
    else: raise newException(ValueError, "Invalid input: " & c)

  if result >= base:
    raise newException(ValueError, "Invalid input: " & c)

func filterUnderscores(str: var string) {.inline.} =
  var k = 0 # the amount of underscores
  for i in 0 .. str.high:
    let c = str[i]
    if c == '_':
      inc k
    elif k > 0:
      str[i - k] = c
  str.setLen(str.len - k)

func initBigInt*(str: string, base: range[2..36] = 10): BigInt =
  ## Create a `BigInt` from a string. For invalid inputs, a `ValueError` exception is raised.
  runnableExamples:
    let
      a = initBigInt("1234")
      b = initBigInt("1234", base = 8)
    assert a == 1234.initBigInt
    assert b == 668.initBigInt

  if str.len == 0:
    raise newException(ValueError, "Empty input")

  let size = sizes[base]
  let base = base.uint32
  var first = 0
  var neg = false

  case str[0]
  of '-':
    if str.len == 1:
      raise newException(ValueError, "Invalid input: " & str)
    first = 1
    neg = true
  of '+':
    if str.len == 1:
      raise newException(ValueError, "Invalid input: " & str)
    first = 1
  else:
    discard
  if str[first] == '_':
    raise newException(ValueError, "A number can not begin with _")
  if str[^1] == '_':
    raise newException(ValueError, "A number can not end with _")

  if base in powers:
    # base is a power of two, so each digit corresponds to a block of bits
    let bits = countTrailingZeroBits(base) # bits per digit
    var
      acc = 0'u32
      accBits = 0 # the number of bits needed for acc
    for i in countdown(str.high, first):
      if str[i] != '_':
        let digit = parseDigit(str[i], base)
        acc = acc or (digit shl accBits)
        accBits += bits
        if accBits >= 32:
          result.limbs.add(acc)
          accBits -= 32
          acc = digit shr (bits - accBits)
    if acc > 0:
      result.limbs.add(acc)
    result.normalize()
  else:
    var str = str
    filterUnderscores(str)
    let d = initBigInt(base ^ size)
    for i in countup(first, str.high, size):
      var num = 0'u32 # the accumulator in this block
      if i + size <= str.len:
        # iterator over a block of length `size`, so we can use `d`
        for j in countup(i, i + size - 1):
          if str[j] != '_':
            let digit = parseDigit(str[j], base)
            num = (num * base) + digit
        unsignedAdditionInt(result, result * d, num)
      else:
        # iterator over a block smaller than `size`, so we have to compute `mul`
        var mul = 1'u32 # the multiplication factor for num
        for j in countup(i, min(i + size - 1, str.high)):
          if str[j] != '_':
            let digit = parseDigit(str[j], base)
            num = (num * base) + digit
            mul *= base
        unsignedAdditionInt(result, result * initBigInt(mul), num)

  result.isNegative = neg

when (NimMajor, NimMinor) >= (1, 5):
  include bigints/private/literals

func inc*(a: var BigInt, b: int = 1) =
  ## Increase the value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15.initBigInt
    inc a
    assert a == 16.initBigInt
    inc(a, 7)
    assert a == 23.initBigInt

  if b in int32.low..int32.high:
    var c = a
    additionInt(a, c, b.int32)
  else:
    a += initBigInt(b)

func dec*(a: var BigInt, b: int = 1) =
  ## Decrease the value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15.initBigInt
    dec a
    assert a == 14.initBigInt
    dec(a, 5)
    assert a == 9.initBigInt

  if b in int32.low..int32.high:
    var c = a
    subtractionInt(a, c, b.int32)
  else:
    a -= initBigInt(b)

func succ*(a: BigInt, b: int = 1): BigInt =
  ## Returns the `b`-th successor of a `BigInt`.
  result = a
  inc(result, b)

func pred*(a: BigInt, b: int = 1): BigInt =
  ## Returns the `b`-th predecessor of a `BigInt`.
  result = a
  dec(result, b)


iterator countup*(a, b: BigInt, step: int32 = 1): BigInt =
  ## Counts from `a` up to `b` (inclusive) with the given step count.
  var res = a
  while res <= b:
    yield res
    inc(res, step)

iterator countdown*(a, b: BigInt, step: int32 = 1): BigInt =
  ## Counts from `a` down to `b` (inclusive) with the given step count.
  var res = a
  while res >= b:
    yield res
    dec(res, step)

iterator `..`*(a, b: BigInt): BigInt =
  ## Counts from `a` up to `b` (inclusive).
  var res = a
  while res <= b:
    yield res
    inc res

iterator `..<`*(a, b: BigInt): BigInt =
  ## Counts from `a` up to `b` (exclusive).
  var res = a
  while res < b:
    yield res
    inc res


func modulo(a, modulus: BigInt): BigInt =
  ## Like `mod`, but the result is always in the range `[0, modulus-1]`.
  ## `modulus` should be greater than zero.
  result = a mod modulus
  if result < 0:
    result += modulus

func fastLog2*(a: BigInt): int =
  ## Computes the logarithm in base 2 of `a`.
  ## If `a` is negative, returns the logarithm of `abs(a)`.
  ## If `a` is zero, returns -1.
  if a.isZero:
    return -1
  bitops.fastLog2(a.limbs[^1]) + 32*(a.limbs.high)


func invmod*(a, modulus: BigInt): BigInt =
  ## Compute the modular inverse of `a` modulo `modulus`.
  ## The return value is always in the range `[1, modulus-1]`
  runnableExamples:
    invmod(3.initBigInt, 7.initBigInt) = 5.initBigInt

  # extended Euclidean algorithm
  if modulus.isZero:
    raise newException(DivByZeroDefect, "modulus must be nonzero")
  elif modulus.isNegative:
    raise newException(ValueError, "modulus must be strictly positive")
  elif a.isZero:
    raise newException(DivByZeroDefect, "0 has no modular inverse")
  else:
    var
      r0 = modulus
      r1 = a.modulo(modulus)
      t0 = zero
      t1 = one
    var rk, tk: BigInt # otherwise t1 is incorrectly inferred as cursor (https://github.com/nim-lang/Nim/issues/19457)
    while r1 > 0:
      let q = r0 div r1
      rk = r0 - q * r1
      tk = t0 - q * t1
      r0 = r1
      r1 = rk
      t0 = t1
      t1 = tk
    if r0 != one:
      raise newException(ValueError, $a & " has no modular inverse modulo " & $modulus)
    result = t0.modulo(modulus)

func powmod*(base, exponent, modulus: BigInt): BigInt =
  ## Compute modular exponentation of `base` with power `exponent` modulo `modulus`.
  ## The return value is always in the range `[0, modulus-1]`.
  runnableExamples:
    assert powmod(2.initBigInt, 3.initBigInt, 7.initBigInt) == 1.initBigInt
  if modulus.isZero:
    raise newException(DivByZeroDefect, "modulus must be nonzero")
  elif modulus.isNegative:
    raise newException(ValueError, "modulus must be strictly positive")
  elif modulus == 1:
    return zero
  else:
    var
      base = base
      exponent = exponent
    if exponent < 0:
      base = invmod(base, modulus)
      exponent = -exponent
    var basePow = base.modulo(modulus)
    result = one
    while not exponent.isZero:
      if (exponent.limbs[0] and 1) != 0:
        result = (result * basePow) mod modulus
      basePow = (basePow * basePow) mod modulus
      exponent = exponent shr 1
