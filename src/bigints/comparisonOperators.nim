# absolute value and comparison operators <, >, ...
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
