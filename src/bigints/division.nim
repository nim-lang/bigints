# Functions to compute the quotient and the remainder
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
