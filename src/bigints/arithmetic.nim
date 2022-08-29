# (modular) arithmetic functions
include stringConversion

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

func modulo(a, modulus: BigInt): BigInt =
  ## Like `mod`, but the result is always in the range `[0, modulus-1]`.
  ## `modulus` should be greater than zero.
  result = a mod modulus
  if result < 0:
    result += modulus

func invmod*(a, modulus: BigInt): BigInt =
  ## Compute the modular inverse of `a` modulo `modulus`.
  ## The return value is always in the range `[1, modulus-1]`
  runnableExamples:
    assert invmod(3.initBigInt, 7.initBigInt) == 5.initBigInt

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
