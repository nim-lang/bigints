# addition, subtraction and multiplication
include comparisonOperators

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
