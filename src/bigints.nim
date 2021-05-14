## The official library for arbitrary precision integers, implemented in pure
## Nim, without any external dependencies.



import strutils

type
  Flags = enum
    Negative

  BigInt* = object
    limbs: seq[uint32]
    flags: set[Flags]

proc normalize(a: var BigInt) =
  for i in countdown(a.limbs.high, 0):
    if a.limbs[i] > 0'u32:
      a.limbs.setLen(i+1)
      return
  a.limbs.setLen(1)

proc initBigInt*(vals: seq[uint32], flags: set[Flags] = {}): BigInt =
  ## Initialize BigInt from a sequence of `uint32` values.
  runnableExamples:
    let a = @[10'u32, 2'u32].initBigInt
    let b = 10 + 2 shl 32
    assert $a == $b
  result.limbs = vals
  result.flags = flags

proc initBigInt*[T: int8|int16|int32](val: T): BigInt =
  if val < 0:
    result.limbs = @[(not val.int32).uint32 + 1]
    result.flags = {Negative}
  else:
    result.limbs = @[val.int32.uint32]
    result.flags = {}

proc initBigInt*[T: uint8|uint16|uint32](val: T): BigInt =
  result.limbs = @[val.uint32]
  result.flags = {}

proc initBigInt*(val: int64): BigInt =
  var a = val.uint64
  if val < 0:
    a = not a + 1
    result.flags = {Negative}
  else:
    result.flags = {}
  if a > uint32.high.uint64:
    result.limbs = @[(a and uint32.high).uint32, (a shr 32).uint32]
  else:
    result.limbs = @[a.uint32]

proc initBigInt*(val: uint64): BigInt =
  if val > uint32.high.uint64:
    result.limbs = @[(val and uint32.high).uint32, (val shr 32).uint32]
  else:
    result.limbs = @[val.uint32]
  result.flags = {}

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
    elif Negative in b.flags: # b.isNegative
      return 1
    else:
      return -1
  elif Negative in a.flags: # a.isNegative
    if b.isZero or Negative notin b.flags: # b >= 0
      return -1
    else:
      return unsignedCmp(b, a) 
  else: # a > 0
    if b.isZero or Negative in b.flags: # b <= 0
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
  elif Negative in a.flags:  # a.isNegative
    if b < 0:
      return unsignedCmp(b, a)
    else:
      return -1
  else: # a > 0
    if b <= 0:
      return 1
    else:
      return unsignedCmp(b, a)

proc cmp(a: int32, b: BigInt): int64 = -cmp(b, a)

proc `==`*(a, b: BigInt): bool =
  ## Compares if two `BigInt` numbers are equal.
  runnableExamples:
    let
      a = 5'bi
      b = 3'bi
      c = 2'bi
    assert a == b + c
    assert b != c
  cmp(a, b) == 0

proc `<`*(a, b: BigInt): bool =
  runnableExamples:
    let
      a = 5'bi
      b = 3'bi
      c = 2'bi
    assert b < a
    assert b > c
  cmp(a, b) < 0

proc `<=`*(a, b: BigInt): bool =
  runnableExamples:
    let
      a = 5'bi
      b = 3'bi
      c = 2'bi
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
  a.flags.excl(Negative)

# Works when a = b
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
  a.flags.excl(Negative)

proc negate(a: var BigInt) =
  if Negative in a.flags:
    a.flags.excl(Negative)
  else:
    a.flags.incl(Negative)

proc `-`*(a: BigInt): BigInt =
  ## Unary minus for `BigInt`.
  runnableExamples:
    let
      a = 5'bi
      b = -10'bi
    assert (-a) == -5'bi
    assert (-b) == 10'bi
  result = a
  if Negative in a.flags:
    result.flags.excl(Negative)
  else:
    result.flags.incl(Negative)

# Works when a = b
# Assumes positive parameters and b > c
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
  a.flags.excl(Negative)

  normalize(a)
  if tmp > 0:
    a.limbs.add(uint32(tmp))

# Works when a = b
# Assumes positive parameters and b > c
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
    a.flags.incl(Negative)
  else:
    for i in m ..< bl:
      tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - tmp
      a.limbs[i] = uint32(tmp and int64(uint32.high))
      tmp = 1 - (tmp shr 32)
    a.flags.excl(Negative)

  normalize(a)
  if tmp > 0:
    a.limbs.add(uint32(tmp))

proc unsignedSubtractionInt(a: var BigInt, b: BigInt, c: int32) =
  if unsignedCmp(b, c) >= 0:
    realUnsignedSubtractionInt(a, b, c)
  else:
    # TODO: is this right?
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
  elif Negative in b.flags:
    if c < 0:
      unsignedAdditionInt(a, b, c)
      a.flags.incl(Negative)
    else:
      # TODO: is this right?
      unsignedSubtractionInt(a, b, c)
  else:
    if c < 0:
      var c = -c
      unsignedSubtractionInt(a, b, c)
    else:
      unsignedAdditionInt(a, b, c)

proc addition(a: var BigInt, b, c: BigInt) =
  if Negative in b.flags:
    if Negative in c.flags:
      unsignedAddition(a, b, c)
      a.flags.incl(Negative)
    else:
      unsignedSubtraction(a, c, b)
  else:
    if Negative in c.flags:
      unsignedSubtraction(a, b, c)
    else:
      unsignedAddition(a, b, c)

proc `+`*(a, b: BigInt): BigInt=
  runnableExamples:
    let
      a = 5'bi
      b = 10'bi
    assert a + b == 15'bi
    assert (-a) + b == 5'bi
    assert a + (-b) == -5'bi
  result = zero
  addition(result, a, b)

template `+=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 5'bi
    a += 2'bi
    assert a == 7'bi
  var c = a
  addition(a, c, b)

template optAdd*{x = y + z}(x,y,z: BigInt) = addition(x, y, z)

proc subtractionInt(a: var BigInt, b: BigInt, c: int32) =
  if b.isZero:
    a = (-c).initBigInt
  elif Negative in b.flags:
    if c < 0:
      # TODO: is this right?
      unsignedSubtractionInt(a, b, c)
      a.flags.incl(Negative)
    else:
      unsignedAdditionInt(a, b, c)
      a.flags.incl(Negative)
  else:
    if c < 0:
      unsignedAdditionInt(a, b, c)
    else:
      unsignedSubtractionInt(a, b, c)

proc subtraction(a: var BigInt, b, c: BigInt) =
  if Negative in b.flags:
    if Negative in c.flags:
      unsignedSubtraction(a, c, b)
    else:
      unsignedAddition(a, b, c)
      a.flags.incl(Negative)
  else:
    if Negative in c.flags:
      unsignedAddition(a, b, c)
    else:
      unsignedSubtraction(a, b, c)

proc `-`*(a, b: BigInt): BigInt=
  runnableExamples:
    let
      a = 15'bi
      b = 10'bi
    assert a - b == 5'bi
    assert (-a) - b == -25'bi
    assert a - (-b) == 25'bi
  result = zero
  subtraction(result, a, b)

template `-=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 5'bi
    a -= 2'bi
    assert a == 3'bi
  var c = a
  subtraction(a, c, b)

template optSub*{x = y - z}(x,y,z: BigInt) = subtraction(x, y, z)


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


# This doesn't work when a = b
proc multiplication(a: var BigInt, b, c: BigInt) =
  if b.isZero or c.isZero:
    a = zero
    return
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var tmp: uint64

  a.limbs.setLen(bl + cl)
  if cl > bl:
    unsignedMultiplication(a, c, b, cl, bl)
  else:
    unsignedMultiplication(a, b, c, bl, cl)

  if Negative in b.flags:
    if Negative in c.flags:
      a.flags.excl(Negative)
    else:
      a.flags.incl(Negative)
  else:
    if Negative in c.flags:
      a.flags.incl(Negative)
    else:
      a.flags.excl(Negative)

proc `*`*(a, b: BigInt): BigInt =
  runnableExamples:
    let
      a = 421'bi
      b = 200'bi
    assert a * b == 84200'bi
  result = zero
  multiplication(result, a, b)

template `*=`*(a: var BigInt, b: BigInt) =
  runnableExamples:
    var a = 15'bi
    a *= 10'bi
    assert a == 150'bi
  var c = a
  multiplication(a, c, b)

template optMul*{x = `*`(y, z)}(x: BigInt{noalias}, y, z: BigInt) = multiplication(x, y, z)

template optMulSame*{x = `*`(x, z)}(x,z: BigInt) = x *= z

# Works when a = b
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
    let a = 24'bi
    assert a shr 1 == 12'bi
    assert a shr 2 == 6'bi
  result = zero
  shiftRight(result, x, y)

template optShr*{x = y shr z}(x, y: BigInt, z) = shiftRight(x, y, z)

# Works when a = b
proc shiftLeft(a: var BigInt, b: BigInt, c: int) =
  a.limbs.setLen(b.limbs.len)
  var carry: uint32

  for i in 0..b.limbs.high:
    let acc = (uint64(b.limbs[i]) shl uint64(c)) or carry
    a.limbs[i] = uint32(acc and uint32.high)
    carry = uint32(acc shr 32)

  if carry > 0'u32:
    a.limbs.add(carry)

proc `shl`*(x: BigInt, y: int): BigInt =
  ## Computes a left shift of a `BigInt`.
  runnableExamples:
    let a = 24'bi
    assert a shl 1 == 48'bi
    assert a shl 2 == 96'bi
  result = zero
  shiftLeft(result, x, y)

template optShl*{x = y shl z}(x, y: BigInt, z) = shiftLeft(x, y, z)

proc reset*(a: var BigInt) =
  ## Resets a `BigInt` back to the zero value.
  a.limbs.setLen(1)
  a.limbs[0] = 0
  a.flags = {}

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
    r.flags = {}
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
        z.flags.incl Negative
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
          zhi.flags.incl Negative
        elif z < 0:
          zhi.limbs[0] = 1
          zhi.flags.incl Negative
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

  # set signs
  if n < 0 xor d < 0:
    q.flags.incl(Negative)
  else:
    q.flags.excl(Negative)

  if n < 0 and r != 0:
    r.flags.incl(Negative)
  else:
    r.flags.excl(Negative)

  # divrem -> divmod
  if (r < 0 and d > 0) or
     (r > 0 and d < 0):
    r += d
    q -= one

  if q.limbs == @[0'u32]:
    q.flags.excl(Negative)

  if r.limbs == @[0'u32]:
    r.flags.excl(Negative)

proc `div`*(a, b: BigInt): BigInt =
  ## Computes the integer division of two `BigInt` numbers.
  ##
  ## If you also need a modulo (remainder), use the `divmod` proc.
  runnableExamples:
    let
      a = 17'bi
      b = 5'bi
    assert a div b == 3'bi
    assert (-a) div b == -4'bi
    assert a div (-b) == -4'bi
    assert (-a) div (-b) == 3'bi
  result = zero
  var tmp = zero
  division(result, tmp, a, b)

proc `mod`*(a, b: BigInt): BigInt =
  ## Computes the integer modulo (remainder) of two `BigInt` numbers.
  ##
  ## If you also need an integer division, use the `divmod` proc.
  runnableExamples:
    let
      a = 17'bi
      b = 5'bi
    assert a mod b == 2'bi
    assert (-a) mod b == 3'bi
    assert a mod (-b) == -3'bi
    assert (-a) mod (-b) == -2'bi
  result = zero
  var tmp = zero
  division(tmp, result, a, b)

proc `divmod`*(a, b: BigInt): tuple[q, r: BigInt] =
  ## Computes both the integer division and modulo (remainder) of two
  ## `BigInt` numbers.
  runnableExamples:
    let
      a = 17'bi
      b = 5'bi
    assert divmod(a, b) == (3'bi, 2'bi)
  result.q = zero
  result.r = zero
  division(result.q, result.r, a, b)

# TODO: This doesn't work because it's applied before the other rules, which
# should take precedence. This also doesn't work for x = y etc
#template optDiv*{x = y div z}(x,y,z: BigInt) =
#  var tmp = zero
#  division(x, tmp, y, z)
#
#template optMod*{x = y mod z}(x,y,z: BigInt) =
#  var tmp = zero
#  division(tmp, x, y, z)

template optDivMod*{w = y div z; x = y mod z}(w,x,y,z: BigInt) =
  division(w, x, y, z)

template optDivMod2*{w = x div z; x = x mod z}(w,x,z: BigInt) =
  var tmp = x
  division(w, x, tmp, z)

template optDivMod3*{w = w div z; x = w mod z}(w,x,z: BigInt) =
  var tmp = w
  division(w, x, tmp, z)

template optDivMod4*{w = y mod z; x = y div z}(w,x,y,z: BigInt) =
  division(x, w, y, z)

template optDivMod5*{w = x mod z; x = x div z}(w,x,z: BigInt) =
  var tmp = x
  division(x, w, tmp, z)

template optDivMod6*{w = w mod z; x = w div z}(w,x,z: BigInt) =
  var tmp = w
  division(x, w, tmp, z)

const digits = "0123456789abcdefghijklmnopqrstuvwxyz"

const multiples = [2,4,8,16,32]

proc calcSizes(): array[2..36, int] =
  for i in 2..36:
    var x = int64(uint32.high) div i # 1 less so we actually fit
    while x > 0:
      x = x div i
      result[i].inc()


const sizes = calcSizes()

proc toStringMultipleTwo(a: BigInt, base: range[2..36] = 16): string =
  assert(base in multiples)
  var
    size = sizes[base] + 1
    cs = newStringOfCap(size)

  result = newStringOfCap(size * a.limbs.len + 1)
  if Negative in a.flags:
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
    let a = 55'bi
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

  if Negative in a.flags:
    tmp.flags.excl(Negative)
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
    assert a == 1234'bi
    assert b == 668'bi
  result.limbs = @[0'u32]
  result.flags = {}

  var mul = one
  let size = sizes[base]
  var first = 0
  var str = str
  var fs: set[Flags]

  if str[0] == '-':
    first = 1
    fs.incl(Negative)
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
  result.flags = fs

proc `'bi`*(s: string): BigInt =
  ## Create a `BigInt` from a literal, using the suffix `'bi`.
  runnableExamples:
    let
      a = 123'bi
      b = 0xFF'bi
      c = 0b1011'bi
    assert $a == "123"
    assert $b == "255"
    assert $c == "11"
  case s[0..min(s.high, 1)]
  of "0x", "0X": initBigInt(s[2..s.high], base = 16)
  of "0b", "0B": initBigInt(s[2..s.high], base = 2)
  else: initBigInt(s)

proc inc*(a: var BigInt, b: int32 = 1) =
  ## Increase a value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15'bi
    inc a
    assert a == 16'bi
    inc(a, 7)
    assert a == 23'bi
  var c = a
  additionInt(a, c, b)

proc dec*(a: var BigInt, b: int32 = 1) =
  ## Decrease a value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15'bi
    dec a
    assert a == 14'bi
    dec(a, 5)
    assert a == 9'bi
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
