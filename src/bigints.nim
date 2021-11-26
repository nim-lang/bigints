## The official library for arbitrary precision integers, implemented in pure
## Nim, without any external dependencies.


import strutils

type
  BigInt* = object
    limbs: seq[uint32]
    isNegative: bool


proc normalize(a: var BigInt) =
  for i in countdown(a.limbs.high, 0):
    if a.limbs[i] > 0'u32:
      a.limbs.setLen(i+1)
      return
  a.limbs.setLen(1)

proc initBigInt*(vals: sink seq[uint32], isNegative = false): BigInt =
  ## Initialize BigInt from a sequence of `uint32` values.
  runnableExamples:
    let a = @[10'u32, 2'u32].initBigInt
    let b = 10 + 2 shl 32
    assert $a == $b
  result.limbs = vals
  result.isNegative = isNegative

proc initBigInt*[T: int8|int16|int32](val: T): BigInt =
  if val < 0:
    result.limbs = @[(not val.int32).uint32 + 1]
    result.isNegative = true
  else:
    result.limbs = @[val.int32.uint32]
    result.isNegative = false

proc initBigInt*[T: uint8|uint16|uint32](val: T): BigInt =
  result.limbs = @[val.uint32]

proc initBigInt*(val: int64): BigInt =
  var a = val.uint64
  if val < 0:
    a = not a + 1
    result.isNegative = true
  if a > uint32.high.uint64:
    result.limbs = @[(a and uint32.high).uint32, (a shr 32).uint32]
  else:
    result.limbs = @[a.uint32]

proc initBigInt*(val: uint64): BigInt =
  if val > uint32.high.uint64:
    result.limbs = @[(val and uint32.high).uint32, (val shr 32).uint32]
  else:
    result.limbs = @[val.uint32]

when sizeof(int) == 4:
  template initBigInt*(val: int): BigInt = initBigInt(val.int32)
  template initBigInt*(val: uint): BigInt = initBigInt(val.uint32)
else:
  template initBigInt*(val: int): BigInt = initBigInt(val.int64)
  template initBigInt*(val: uint): BigInt = initBigInt(val.uint64)

proc initBigInt*(val: BigInt): BigInt =
  result = val

const
  zero = initBigInt(0)
  one = initBigInt(1)

proc isZero(a: BigInt): bool {.inline.} =
  for i in countdown(a.limbs.high, 0):
    if a.limbs[i] != 0'u32:
      return false
  return true

proc unsignedCmp(a: BigInt, b: int32): int64 =
  # here a and b have same sign a none of them is zero.
  # in particular we have that a.limbs.len >= 1
  result = int64(a.limbs.len) - 1
  if result != 0: return
  result = int64(a.limbs[0]) - int64(b)

proc unsignedCmp(a: int32, b: BigInt): int64 = -unsignedCmp(b, a)

proc unsignedCmp(a, b: BigInt): int64 =
  result = int64(a.limbs.len) - int64(b.limbs.len)
  if result != 0: return
  for i in countdown(a.limbs.high, 0):
    result = int64(a.limbs[i]) - int64(b.limbs[i])
    if result != 0:
      return

proc cmp(a, b: BigInt): int64 =
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

proc cmp(a: BigInt, b: int32): int64 =
  ## Returns:
  ## * a value less than zero, if `a < b`
  ## * a value greater than zero, if `a > b`
  ## * zero, if `a == b`
  if a.isZero:
    if b < 0:
      return 1
    elif b == 0:
      return 0
    else:
      return -1
  elif a.isNegative:
    if b < 0:
      return unsignedCmp(b, a)
    else:
      return -1
  else: # a > 0
    if b <= 0:
      return 1
    else:
      return unsignedCmp(a, b)

proc cmp(a: int32, b: BigInt): int64 = -cmp(b, a)

proc `==`*(a, b: BigInt): bool =
  ## Compares if two `BigInt` numbers are equal.
  runnableExamples:
    let
      a = 5.initBigInt
      b = 3.initBigInt
      c = 2.initBigInt
    assert a == b + c
    assert b != c
  cmp(a, b) == 0

proc `<`*(a, b: BigInt): bool =
  runnableExamples:
    let
      a = 5.initBigInt
      b = 3.initBigInt
      c = 2.initBigInt
    assert b < a
    assert b > c
  cmp(a, b) < 0

proc `<=`*(a, b: BigInt): bool =
  runnableExamples:
    let
      a = 5.initBigInt
      b = 3.initBigInt
      c = 2.initBigInt
    assert a <= b + c
    assert c <= b
  cmp(a, b) <= 0

proc `==`(a: BigInt, b: int32): bool = cmp(a, b) == 0
proc `<`(a: BigInt, b: int32): bool = cmp(a, b) < 0
proc `<`(a: int32, b: BigInt): bool = cmp(a, b) < 0

template addParts(toAdd) =
  tmp += toAdd
  a.limbs[i] = uint32(tmp and uint32.high)
  tmp = tmp shr 32

proc unsignedAdditionInt(a: var BigInt, b: BigInt, c: int32) =
  var tmp: uint64

  let bl = b.limbs.len
  const m = 1
  a.limbs.setLen(bl)

  tmp = uint64(b.limbs[0]) + uint64(c)
  a.limbs[0] = uint32(tmp and uint32.high)
  tmp = tmp shr 32

  for i in m ..< bl:
    addParts(uint64(b.limbs[i]))
  if tmp > 0'u64:
    a.limbs.add(uint32(tmp))
  a.isNegative = false

proc unsignedAddition(a: var BigInt, b, c: BigInt) =
  var tmp: uint64
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var m = if bl < cl: bl else: cl
  a.limbs.setLen(if bl < cl: cl else: bl)

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

proc negate(a: var BigInt) =
  a.isNegative = not a.isNegative

proc `-`*(a: BigInt): BigInt =
  ## Unary minus for `BigInt`.
  runnableExamples:
    let
      a = 5.initBigInt
      b = -10.initBigInt
    assert (-a) == -5.initBigInt
    assert (-b) == 10.initBigInt
  result = a
  negate(result)

template realUnsignedSubtractionInt(a: var BigInt, b: BigInt, c: int32) =
  var tmp: int64

  let bl = b.limbs.len
  const cl = 1
  const m = cl
  a.limbs.setLen(bl)

  block:
    const i = 0
    tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - int64(c)
    a.limbs[i] = uint32(tmp and int64(uint32.high))
    tmp = 1 - (tmp shr 32)

  for i in m ..< bl:
    tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - tmp
    a.limbs[i] = uint32(tmp and int64(uint32.high))
    tmp = 1 - (tmp shr 32)
  a.isNegative = false

  normalize(a)
  if tmp > 0:
    a.limbs.add(uint32(tmp))

template realUnsignedSubtraction(a: var BigInt, b, c: BigInt) =
  var tmp: int64
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var m = if bl < cl: bl else: cl
  a.limbs.setLen(if bl < cl: cl else: bl)

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
  if tmp > 0:
    a.limbs.add(uint32(tmp))

proc unsignedSubtractionInt(a: var BigInt, b: BigInt, c: int32) =
  if unsignedCmp(b, c) >= 0:
    realUnsignedSubtractionInt(a, b, c)
  else:
    realUnsignedSubtractionInt(a, b, c)
    if a.limbs != @[0'u32]:
      negate(a)

proc unsignedSubtraction(a: var BigInt, b, c: BigInt) =
  if unsignedCmp(b, c) > 0:
    realUnsignedSubtraction(a, b, c)
  else:
    realUnsignedSubtraction(a, c, b)
    if a.limbs != @[0'u32]:
      negate(a)

proc additionInt(a: var BigInt, b: BigInt, c: int32) =
  if b.isZero:
    a = c.initBigInt
  elif b.isNegative:
    if c < 0:
      unsignedAdditionInt(a, b, c)
      a.isNegative = true
    else:
      unsignedSubtractionInt(a, b, c)
  else:
    if c < 0:
      var c = -c
      unsignedSubtractionInt(a, b, c)
    else:
      unsignedAdditionInt(a, b, c)

proc addition(a: var BigInt, b, c: BigInt) =
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

proc `+`*(a, b: BigInt): BigInt=
  runnableExamples:
    let
      a = 5.initBigInt
      b = 10.initBigInt
    assert a + b == 15.initBigInt
    assert (-a) + b == 5.initBigInt
    assert a + (-b) == -5.initBigInt
  result = zero
  addition(result, a, b)

template `+=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 5.initBigInt
    a += 2.initBigInt
    assert a == 7.initBigInt
  var c = a
  addition(a, c, b)

proc subtractionInt(a: var BigInt, b: BigInt, c: int32) =
  if b.isZero:
    a = (-c).initBigInt
  elif b.isNegative:
    if c < 0:
      unsignedSubtractionInt(a, b, c)
      a.isNegative = true
    else:
      unsignedAdditionInt(a, b, c)
      a.isNegative = true
  else:
    if c < 0:
      unsignedAdditionInt(a, b, c)
    else:
      unsignedSubtractionInt(a, b, c)

proc subtraction(a: var BigInt, b, c: BigInt) =
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

proc `-`*(a, b: BigInt): BigInt=
  runnableExamples:
    let
      a = 15.initBigInt
      b = 10.initBigInt
    assert a - b == 5.initBigInt
    assert (-a) - b == -25.initBigInt
    assert a - (-b) == 25.initBigInt
  result = zero
  subtraction(result, a, b)

template `-=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 5.initBigInt
    a -= 2.initBigInt
    assert a == 3.initBigInt
  var c = a
  subtraction(a, c, b)


template unsignedMultiplication(a: BigInt, b, c: BigInt, bl, cl) =
  # always called with bl >= cl

  for i in 0 ..< bl:
    tmp += uint64(b.limbs[i]) * uint64(c.limbs[0])
    a.limbs[i] = uint32(tmp and uint32.high)
    tmp = tmp shr 32

  for i in bl ..< bl + cl:
    a.limbs[i] = 0
  var pos = bl

  while tmp > 0'u64:
    a.limbs[pos] = uint32(tmp and uint32.high)
    tmp = tmp shr 32
    pos.inc()

  for j in 1 ..< cl:
    for i in 0 ..< bl:
      tmp += uint64(a.limbs[j + i]) + uint64(b.limbs[i]) * uint64(c.limbs[j])
      a.limbs[j + i] = uint32(tmp and uint32.high)
      tmp = tmp shr 32
    pos = j + bl
    while tmp > 0'u64:
      tmp += uint64(a.limbs[pos])
      a.limbs[pos] = uint32(tmp and uint32.high)
      tmp = tmp shr 32
      pos.inc()
  normalize(a)

proc multiplication(a: var BigInt, b, c: BigInt) =
  if b.isZero or c.isZero:
    a = zero
    return
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var tmp: uint64
  var c = c

  a.limbs.setLen(bl + cl)
  if cl > bl:
    unsignedMultiplication(a, c, b, cl, bl)
  else:
    unsignedMultiplication(a, b, c, bl, cl)
  a.isNegative = b.isNegative xor c.isNegative

proc `*`*(a, b: BigInt): BigInt =
  runnableExamples:
    let
      a = 421.initBigInt
      b = 200.initBigInt
    assert a * b == 84200.initBigInt
  result = zero
  multiplication(result, a, b)

template `*=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 15.initBigInt
    a *= 10.initBigInt
    assert a == 150.initBigInt
  var c = a
  multiplication(a, c, b)

proc shiftRight(a: var BigInt, b: BigInt, c: int) =
  a.limbs.setLen(b.limbs.len)
  var carry: uint64
  let d = c div 32
  let e = c mod 32
  let mask: uint32 = 1'u32 shl uint32(e) - 1

  for i in countdown(b.limbs.high, d):
    let acc: uint64 = (carry shl 32) or b.limbs[i]
    carry = uint32(acc and mask)
    a.limbs[i - d] = uint32(acc shr uint32(e))

  a.limbs.setLen(a.limbs.len - d)

  if a.limbs.len > 1 and a.limbs[a.limbs.high] == 0:
    a.limbs.setLen(a.limbs.high)

proc `shr`*(x: BigInt, y: int): BigInt =
  ## Computes a right shift of a `BigInt`.
  runnableExamples:
    let a = 24.initBigInt
    assert a shr 1 == 12.initBigInt
    assert a shr 2 == 6.initBigInt
  result = zero
  shiftRight(result, x, y)

proc pow*(x: BigInt, y: int): BigInt =
  var base = x
  var exp = y
  result = one

  while exp > 0:
    if exp mod 2 > 0:
      result *= base
    exp = exp div 2
    var tmp = base
    base *= tmp

proc `shl`*(x: BigInt, y: int): BigInt =
  ## Computes a left shift of a `BigInt`.
  runnableExamples:
    let a = 24.initBigInt
    assert a shl 1 == 48.initBigInt
    assert a shl 2 == 96.initBigInt
  var powerOfTwo = pow(2.initBigInt, y)
  result = x * powerOfTwo

proc bitwiseAnd(a: var BigInt, b, c: BigInt) =
  a.limbs.setLen(min(b.limbs.len, c.limbs.len))
  for i in 0 ..< a.limbs.len:
    a.limbs[i] = b.limbs[i] and c.limbs[i]

proc `and`*(a, b: BigInt): BigInt =
  assert (not a.isNegative) and (not b.isNegative)
  bitwiseAnd(result, a, b)

proc bitwiseOr(a: var BigInt, b, c: BigInt) =
  # `b` must be smaller than `c`
  a.limbs.setLen(c.limbs.len)
  for i in 0 ..< b.limbs.len:
    a.limbs[i] = b.limbs[i] or c.limbs[i]
  for i in b.limbs.len ..< c.limbs.len:
    a.limbs[i] = c.limbs[i]

proc `or`*(a, b: BigInt): BigInt =
  assert (not a.isNegative) and (not b.isNegative)
  if a.limbs.len <= b.limbs.len:
    bitwiseOr(result, a, b)
  else:
    bitwiseOr(result, b, a)

proc bitwiseXor(a: var BigInt, b, c: BigInt) =
  # `b` must be smaller than `c`
  a.limbs.setLen(c.limbs.len)
  for i in 0 ..< b.limbs.len:
    a.limbs[i] = b.limbs[i] xor c.limbs[i]
  for i in b.limbs.len ..< c.limbs.len:
    a.limbs[i] = c.limbs[i]

proc `xor`*(a, b: BigInt): BigInt =
  assert (not a.isNegative) and (not b.isNegative)
  if a.limbs.len <= b.limbs.len:
    bitwiseXor(result, a, b)
  else:
    bitwiseXor(result, b, a)

proc reset(a: var BigInt) =
  ## Resets a `BigInt` back to the zero value.
  a.limbs.setLen(1)
  a.limbs[0] = 0
  a.isNegative = false

proc unsignedDivRem(q: var BigInt, r: var uint32, n: BigInt, d: uint32) =
  q.limbs.setLen(n.limbs.len)
  r = 0
  for i in countdown(n.limbs.high, 0):
    let tmp: uint64 = uint64(n.limbs[i]) + uint64(r) shl 32
    q.limbs[i] = uint32(tmp div d)
    r = uint32(tmp mod d)
  while q.limbs.len > 1 and q.limbs[q.limbs.high] == 0:
    q.limbs.setLen(q.limbs.high)

proc bits(d: uint32): int =
  const bitLengths = [0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4,
                      5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]
  var d = d
  while d >= 32'u32:
    result += 6
    d = d shr 6
  result += bitLengths[int(d)]

# From Knuth and Python
proc unsignedDivRem(q, r: var BigInt, n, d: BigInt) =
  var
    nn = n.limbs.len
    dn = d.limbs.len

  if nn == 0:
    q.reset()
    r.reset()
  elif nn < dn:
    r = n
    q.reset()
  elif dn == 1:
    var x: uint32
    unsignedDivRem(q, x, n, d.limbs[0])
    r.limbs.setLen(1)
    r.limbs[0] = x
    r.isNegative = false
  else:
    assert nn >= dn and dn >= 2
    var carry: uint64

    # normalize
    let ls = 32 - bits(d.limbs[d.limbs.high])
    r = d shl ls
    q = n shl ls
    if q.limbs.len > n.limbs.len or q.limbs[q.limbs.high] >= r.limbs[r.limbs.high]:
      q.limbs.add(0'u32)
      inc(nn)

    let k = nn - dn
    assert k >= 0
    var a = zero
    a.limbs.setLen(k)
    let wm1 = r.limbs[r.limbs.high]
    let wm2 = r.limbs[r.limbs.high-1]
    var ak = k

    var zhi = 0.initBigInt
    var z = 0.initBigInt
    var qib = 0.initBigInt
    var q1b = 0.initBigInt

    for v in countdown(k-1, 0):
      # estimate quotient digit, may rarely overestimate by 1
      let vtop = q.limbs[v + dn]
      assert vtop <= wm1
      let vv = (uint64(vtop) shl 32) or q.limbs[v+dn-1]
      var q1 = uint64(vv) div wm1
      var r1 = uint64(vv) mod wm1

      while (uint64(wm2)*q1) > ((r1 shl 32) or q.limbs[v+dn-2]):
        dec(q1)
        r1 += wm1
        if r1 > uint64(uint32.high):
          break

      assert q1 <= uint64(uint32.high)

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
        carry = 0
        for i in 0 ..< dn:
          carry += q.limbs[v+i]
          carry += r.limbs[i]
          q.limbs[v+i] = uint32(carry and uint32.high)
          carry = carry shr 32
        dec(q1)

      # store quotient digit
      assert q1 <= uint64(uint32.high)
      dec(ak)
      a.limbs[ak] = uint32(q1)

    # unshift remainder, we reuse w1 to store the result
    q.limbs.setLen(dn)
    r = q shr ls

    normalize(r)
    q = a
    normalize(q)

proc division(q, r: var BigInt, n, d: BigInt) =
  unsignedDivRem(q, r, n, d)

  q.isNegative = n < 0 xor d < 0
  r.isNegative = n < 0 and r != 0

  # divrem -> divmod
  if (r < 0 and d > 0) or
     (r > 0 and d < 0):
    r += d
    q -= one

  if q.limbs == @[0'u32]:
    q.isNegative = false

  if r.limbs == @[0'u32]:
    r.isNegative = false

proc `div`*(a, b: BigInt): BigInt =
  ## Computes the integer division of two `BigInt` numbers.
  ##
  ## If you also need a modulo (remainder), use the `divmod` proc.
  runnableExamples:
    let
      a = 17.initBigInt
      b = 5.initBigInt
    assert a div b == 3.initBigInt
    assert (-a) div b == -4.initBigInt
    assert a div (-b) == -4.initBigInt
    assert (-a) div (-b) == 3.initBigInt
  result = zero
  var tmp = zero
  division(result, tmp, a, b)

proc `mod`*(a, b: BigInt): BigInt =
  ## Computes the integer modulo (remainder) of two `BigInt` numbers.
  ##
  ## If you also need an integer division, use the `divmod` proc.
  runnableExamples:
    let
      a = 17.initBigInt
      b = 5.initBigInt
    assert a mod b == 2.initBigInt
    assert (-a) mod b == 3.initBigInt
    assert a mod (-b) == -3.initBigInt
    assert (-a) mod (-b) == -2.initBigInt
  result = zero
  var tmp = zero
  division(tmp, result, a, b)

proc `divmod`*(a, b: BigInt): tuple[q, r: BigInt] =
  ## Computes both the integer division and modulo (remainder) of two
  ## `BigInt` numbers.
  runnableExamples:
    let
      a = 17.initBigInt
      b = 5.initBigInt
    assert divmod(a, b) == (3.initBigInt, 2.initBigInt)
  result.q = zero
  result.r = zero
  division(result.q, result.r, a, b)


proc calcSizes(): array[2..36, int] =
  for i in 2..36:
    var x = int64(uint32.high) div i # 1 less so we actually fit
    while x > 0:
      x = x div i
      result[i].inc()

const
  digits = "0123456789abcdefghijklmnopqrstuvwxyz"
  multiples = [2,4,8,16,32]
  sizes = calcSizes()

proc toStringMultipleTwo(a: BigInt, base: range[2..36] = 16): string =
  assert(base in multiples)
  var
    size = sizes[base] + 1
    cs = newStringOfCap(size)

  result = newStringOfCap(size * a.limbs.len + 1)
  if a.isNegative:
    result.add('-')

  # Special case for the highest
  var x = a.limbs[a.limbs.high]
  while x > 0'u32:
    cs.add(digits[int(x mod base.uint32)])
    x = x div base.uint32
  for j in countdown(cs.high, 0):
    result.add(cs[j])

  cs.setLen(size)

  for i in countdown(a.limbs.high - 1, 0):
    var x = a.limbs[i]
    for i in 0 ..< size:
      cs[size - i - 1] = digits[int(x mod base.uint32)]
      x = x div base.uint32
    result.add(cs)

  if result.len == 0:
    result.add('0')

proc reverse(a: string): string =
  result = newString(a.len)
  for i, c in a:
    result[a.high - i] = c

proc `^`(base, exp: uint32): uint32 =
  var
    base = base
    exp = exp
  result = 1
  while exp != 0:
    if (exp and 1) != 0:
      result *= base
    exp = exp shr 1
    base *= base

proc toString*(a: BigInt, base: range[2..36] = 10): string =
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
  if base in multiples:
    return toStringMultipleTwo(a, base)
  var
    tmp = a
    c = 0'u32
    d = uint32(base) ^ uint32(sizes[base])
    s = ""

  if a.isNegative:
    tmp.isNegative = false
    result.add('-')

  while tmp > 0:
    unsignedDivRem(tmp, c, tmp, d)
    for i in 1 .. sizes[base]:
      s.add(digits[int(c mod base.uint32)])
      c = c div base.uint32

  var lastDigit = s.high
  while lastDigit > 0:
    if s[lastDigit] != '0':
      break
    dec lastDigit

  s.setLen(lastDigit+1)
  if s.len == 0: s = "0"
  result.add(reverse(s))

proc `$`*(a: BigInt): string =
  ## String representation of a `BigInt` in base 10.
  toString(a, 10)

proc initBigInt*(str: string, base: range[2..36] = 10): BigInt =
  ## Create a `BigInt` from a string.
  runnableExamples:
    let
      a = initBigInt("1234")
      b = initBigInt("1234", base = 8)
    assert a == 1234.initBigInt
    assert b == 668.initBigInt
  result.limbs = @[0'u32]
  result.isNegative = false

  var mul = one
  let size = sizes[base]
  var first = 0
  var str = str
  var neg = false

  if str[0] == '-':
    first = 1
    neg = true
    str[0] = '0'

  for i in countdown((str.high div size) * size, 0, size):
    var smul = 1'u32
    var num: uint32
    for j in countdown(min(i + size - 1, str.high), max(i, first)):
      let c = toLowerAscii(str[j])

      # This is pretty expensive
      if c notin digits[0 .. base-1]:
        raise newException(ValueError, "Invalid input: " & str[j])

      case c
      of '0'..'9': num += smul * uint32(ord(c) - ord('0'))
      of 'a'..'z': num += smul * uint32(ord(c) - ord('a') + 10)
      else: raise newException(ValueError, "Invalid input: " & str[j])

      smul *= base.uint32
    result += mul * initBigInt(num)
    mul *= initBigInt(smul)
  result.isNegative = neg

when (NimMajor, NimMinor) >= (1, 5):
  include bigints/private/literals

proc inc*(a: var BigInt, b: int32 = 1) =
  ## Increase a value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15.initBigInt
    inc a
    assert a == 16.initBigInt
    inc(a, 7)
    assert a == 23.initBigInt
  var c = a
  additionInt(a, c, b)

proc dec*(a: var BigInt, b: int32 = 1) =
  ## Decrease a value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15.initBigInt
    dec a
    assert a == 14.initBigInt
    dec(a, 5)
    assert a == 9.initBigInt
  var c = a
  subtractionInt(a, c, b)


iterator countup*(a, b: BigInt, step: int32 = 1): BigInt {.inline.} =
  var res = a
  while res <= b:
    yield res
    inc(res, step)

iterator countdown*(a, b: BigInt, step: int32 = 1): BigInt {.inline.} =
  var res = a
  while res >= b:
    yield res
    dec(res, step)

iterator `..`*(a, b: BigInt): BigInt {.inline.} =
  var res = a
  while res <= b:
    yield res
    inc res

iterator `..<`*(a, b: BigInt): BigInt {.inline.} =
  var res = a
  while res < b:
    yield res
    inc res
