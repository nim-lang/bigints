import unsigned, strutils

type
  Flags = enum
    Negative

  BigInt* = tuple
    limbs: seq[uint32]
    flags: set[Flags]

proc `$`*(a: BigInt) : string

const debug = false

template log(x) =
  if debug:
    debugEcho x

const maxInt = int64(high uint32)

proc initBigInt*(vals: seq[uint32], flags: set[Flags] = {}): BigInt =
  result.limbs = vals
  result.flags = flags

proc initBigInt*[T: int|int16|int32|int64|uint|uint16|uint32|uint64](val: T): BigInt =
  result.limbs = @[uint32(val)]
  result.flags = {}
  if int64(val) < 0:
    result.flags.incl(Negative)

template unsignedCmp(a, b: BigInt) =
  result = int64(a.limbs.len) - int64(b.limbs.len)

  if result != 0:
    return

  for i in countdown(a.limbs.high, 0):
    result = int64(a.limbs[i]) - int64(b.limbs[i])

    if result != 0:
      return

proc cmp*(a, b: BigInt): int64 =
  case Negative in a.flags
  of true:
    case Negative in b.flags
    of true: unsignedCmp(b, a)
    of false: return -1
  of false:
    case Negative in b.flags
    of true: return 1
    of false: unsignedCmp(a, b)

proc `<` *(a, b: BigInt): bool = cmp(a, b) < 0

proc `<=` *(a, b: BigInt): bool = cmp(a, b) <= 0

proc `==` *(a, b: BigInt): bool = cmp(a, b) == 0

template addParts(toAdd) =
  tmp += toAdd
  a.limbs[i] = uint32(tmp)
  tmp = tmp shr 32

# Works when a = b
proc unsignedAddition(a: var BigInt, b, c: BigInt) =
  var tmp: uint64

  let
    bl = b.limbs.len
    cl = c.limbs.len
  var m = if bl < cl: bl else: cl

  a.limbs.setLen(if bl < cl: cl else: bl)

  for i in 0 .. < m:
    addParts(uint64(b.limbs[i]) + uint64(c.limbs[i]))

  if bl < cl:
    for i in m .. < cl:
      addParts(uint64(c.limbs[i]))
  else:
    for i in m .. < bl:
      addParts(uint64(b.limbs[i]))

  if tmp > 0'u64:
    a.limbs.add(uint32(tmp))

  a.flags.excl(Negative)

# Works when a = b
# Assumes positive parameters and b > c
proc unsignedSubtraction(a: var BigInt, b, c: BigInt) =
  var tmp: int64

  let
    bl = b.limbs.len
    cl = c.limbs.len
  var m = if bl < cl: bl else: cl

  a.limbs.setLen(if bl < cl: cl else: bl)

  for i in 0 .. < m:
    tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - int64(c.limbs[i]) - tmp
    a.limbs[i] = uint32(tmp)
    tmp = 1 - (tmp shr 32)

  if bl < cl:
    for i in m .. < cl:
      tmp = int64(uint32.high) + 1 - int64(c.limbs[i]) - tmp
      a.limbs[i] = uint32(tmp)
      tmp = 1 - (tmp shr 32)
    a.flags.incl(Negative)
  else:
    for i in m .. < bl:
      tmp = int64(uint32.high) + 1 + int64(b.limbs[i]) - tmp
      a.limbs[i] = uint32(tmp)
      tmp = 1 - (tmp shr 32)
    a.flags.excl(Negative)

  block remover:
    for i in countdown(a.limbs.high, 0):
      if a.limbs[i] > 0'u32:
        a.limbs.setLen(i + 1)
        break remover
    a.limbs.setLen(1)

  if tmp > 0:
    a.limbs.add(uint32(tmp))

proc addition(a: var BigInt, b, c: BigInt) =
  case Negative in b.flags
  of true:
    case Negative in c.flags
    of true:
      unsignedAddition(a, b, c)
      a.flags.incl(Negative)
    of false:
      unsignedSubtraction(a, c, b)
  of false:
    case Negative in c.flags
    of true:
      unsignedSubtraction(a, b, c)
    of false:
      unsignedAddition(a, b, c)

proc `+` *(a, b: BigInt): BigInt=
  result = initBigInt(0)
  addition(result, a, b)

template `+=` *(a: var BigInt, b: BigInt) =
  let c = a
  addition(a, c, b)

template optAdd{x = y + z}(x,y,z: BigInt) = addition(x, y, z)

proc subtraction(a: var BigInt, b, c: BigInt) =
  case Negative in b.flags
  of true:
    case Negative in c.flags
    of true:
      unsignedSubtraction(a, c, b)
    of false:
      unsignedAddition(a, b, c)
      a.flags.incl(Negative)
  of false:
    case Negative in c.flags
    of true:
      unsignedAddition(a, b, c)
    of false:
      unsignedSubtraction(a, b, c)

proc `-` *(a, b: BigInt): BigInt=
  result = initBigInt(0)
  subtraction(result, a, b)

template `-=` *(a: var BigInt, b: BigInt) =
  let c = a
  subtraction(a, c, b)

template optSub{x = y - z}(x,y,z: BigInt) = subtraction(x, y, z)

template unsignedMultiplication(a: BigInt, b, c: BigInt, bl, cl) =
  for i in 0 .. < bl:
    tmp += uint64(b.limbs[i]) * uint64(c.limbs[0])
    a.limbs[i] = uint32(tmp)
    tmp = tmp shr 32

  for i in bl .. < bl + cl:
    a.limbs[i] = 0

  var pos = bl

  while tmp > 0'u64:
    a.limbs[pos] = uint32(tmp)
    tmp = tmp shr 32
    pos.inc()

  for j in 1 .. < cl:
    for i in 0 .. < bl:
      # TODO: Fix: Two carries
      tmp += uint64(a.limbs[j + i]) + uint64(b.limbs[i]) * uint64(c.limbs[j])
      a.limbs[j + i] = uint32(tmp)
      tmp = tmp shr 32

    pos = j + bl
    while tmp > 0'u64:
      tmp += uint64(a.limbs[pos])
      a.limbs[pos] = uint32(tmp)
      tmp = tmp shr 32
      pos.inc()

  if a.limbs[a.limbs.high] == 0:
    a.limbs.setLen(bl + cl - 1)

# This doesn't work when a = b
proc multiplication(a: var BigInt, b, c: BigInt) =
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var tmp: uint64

  a.limbs.setLen(bl + cl)

  if cl > bl:
    unsignedMultiplication(a, c, b, cl, bl)
  else:
    unsignedMultiplication(a, b, c, bl, cl)

  case Negative in b.flags
  of true:
    case Negative in c.flags
    of true: a.flags.excl(Negative)
    of false: a.flags.incl(Negative)
  of false:
    case Negative in b.flags
    of true: a.flags.incl(Negative)
    of false: a.flags.excl(Negative)

proc `*` *(a, b: BigInt): BigInt =
  result = initBigInt(0)
  multiplication(result, a, b)

template `*=` *(a: var BigInt, b: BigInt) =
  let c = a
  multiplication(a, c, b)

# noalias doesn't work yet (i think): https://github.com/Araq/Nimrod/issues/206
# so we set the templates in the correct order instead
template optMul{x = `*`(y, z)}(x,y,z: BigInt) = multiplication(x, y, z)

template optMulSame{x = `*`(x, z)}(x,z: BigInt) = x *= z

# Works when a = b
proc shiftRight(a: var BigInt, b: BigInt, c: int) =
  let
    big = c div 32
    al = b.limbs.len - big
  var carry: uint32

  for i in countdown(al - 1, 0):
    a.limbs[i] = carry or (b.limbs[i + big] shr uint32(c mod 32))
    carry = uint32(uint64(b.limbs[i + big]) shl 32'u32 - uint32(c mod 32))

  a.limbs.setLen(al)

proc `shr` *(x: BigInt, y: int): BigInt =
  result = initBigInt(0)
  shiftRight(result, x, y)

template optShr{x = y shr z}(x, y: BigInt, z) = shiftRight(x, y, z)

# Works when a = b
proc shiftLeft(a: var BigInt, b: BigInt, c: int) =
  let
    big = c div 32
    al = b.limbs.len + big
  var carry, tmp: uint32

  a.limbs.setLen(al)

  for i in 0 .. < big:
    a.limbs[i] = 0

  for i in big .. < al:
    a.limbs[i] = carry or (b.limbs[i - big] shl uint32(c mod 32))
    carry = uint32(uint64(b.limbs[i - big]) shr 32'u32 - uint32(c mod 32))

  if carry > 0'u32:
    a.limbs.add(carry)

proc `shl` *(x: BigInt, y: int): BigInt =
  result = initBigInt(0)
  shiftLeft(result, x, y)

template optShl{x = y shl z}(x, y: BigInt, z) = shiftLeft(x, y, z)

proc reset(a: var BigInt) =
  a.limbs.setLen(1)
  a.limbs[0] = 0
  a.flags = {}

# Terribly inefficient
proc division(q, r: var BigInt, n, d: BigInt) =
  let
    nn = n.limbs.len
    dn = d.limbs.len

  if nn == 0:
    q.reset()
    r.reset()

  elif nn < dn:
    r = n
    q.reset()

  else:
    r = n
    q.reset()

    while r >= d:
      r -= d
      q += initBigInt(1)

proc `div` *(a, b: BigInt): BigInt =
  result = initBigInt(0)
  var tmp = initBigInt(0)
  division(result, tmp, a, b)

proc `mod` *(a, b: BigInt): BigInt =
  result = initBigInt(0)
  var tmp = initBigInt(0)
  division(tmp, result, a, b)

proc `divmod` *(a, b: BigInt): tuple[q, r: BigInt] =
  result.q = initBigInt(0)
  result.r = initBigInt(0)
  division(result.q, result.r, a, b)

template optDiv{x = y div z}(x,y,z: BigInt) =
  var tmp = initBigInt(0)
  division(x, tmp, y, z)

template optMod{x = y mod z}(x,y,z: BigInt) =
  var tmp = initBigInt(0)
  division(tmp, x, y, z)

template optDivMod{w = y div z; x = y mod z}(w,x,y,z: BigInt) =
  division(w, x, y, z)

template optDivMod2{w = x div z; x = x mod z}(w,x,z: BigInt) =
  var tmp = x
  division(w, x, tmp, z)

template optDivMod3{w = w div z; x = w mod z}(w,x,z: BigInt) =
  var tmp = w
  division(w, x, tmp, z)

const digits = "0123456789abcdefghijklmnopqrstuvwxyz"

const multiples = [2,4,8,16,32]

# Should be const, unfortunately not working right now
let sizes: array[2..36, int] = [31,20,15,13,12,11,10,10,9,9,8,8,8,8,7,7,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,6,6,6,6]
# Ideally calculate sizes with:
#var x = uint32.high div base # 1 less so we actually fit
#while x > 0'u32:
#  x = x div base
#  size.inc()

# Only multiples of 2 so far
# TODO: General case requires fast division
proc toStringMultipleTwo(a: BigInt, base: range[2..36] = 16): string =
  assert(base in multiples)
  var
    size = sizes[base] + 1
    cs = newStringOfCap(size)

  result = newStringOfCap(size * a.limbs.len + 1)
  if Negative in a.flags:
    result.add('-')
  #result.add("0x")

  # Special case for the highest
  var x = a.limbs[a.limbs.high]
  while x > 0'u32:
    cs.add(digits[int(x mod base)])
    x = x div base
  for j in countdown(cs.high, 0):
    result.add(cs[j])

  cs.setLen(size)

  for i in countdown(a.limbs.high - 1, 0):
    var x = a.limbs[i]
    for i in 0 .. < size:
      cs[size - i - 1] = digits[int(x mod base)]
      x = x div base
    result.add(cs)

  if result.len == 0:
    result.add('0')

proc reverse(a: string): string =
  result = newString(a.len)
  for i, c in a:
    result[a.high - i] = c

proc `^`*(base: int, exp: int): int =
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
  if base in multiples:
    return toStringMultipleTwo(a, base)

  var
    b = a
    c = initBigInt(0)
    d = initBigInt(base ^ sizes[base])
    s = ""

  while b > initBigInt(0):
    b = b div d
    c = b mod d
    var x = c.limbs[0]
    while x > 0'u32:
      s.add(digits[int(x mod base)])
      x = x div base

  return reverse(s)

proc `$`*(a: BigInt) : string = toString(a, 10)

proc initBigInt*(str: string, base: range[2..36] = 10): BigInt =
  result.limbs = @[0'u32]
  result.flags = {}

  var mul = initBigInt(1)
  let size = sizes[base]
  var first = 0
  var str = str

  if str[0] == '-':
    first = 1
    result.flags.incl(Negative)
    str[0] = '0'

  for i in countdown((str.high div size) * size, 0, size):
    var smul = 1'u32
    var num: uint32
    for j in countdown(min(i + size - 1, str.high), max(i, first)):
      let c = toLower(str[j])

      # This is pretty expensive
      #if not (c in digits[0..base]):
      #  raise newException(EInvalidValue, "Invalid input: " & str[j])

      case c
      of '0'..'9': num += smul * uint32(ord(c) - ord('0'))
      of 'a'..'z': num += smul * uint32(ord(c) - ord('a') + 10)
      else: raise newException(EInvalidValue, "Invalid input: " & str[j])

      smul *= base
    result += mul * initBigInt(num)
    mul *= initBigInt(smul)

when isMainModule:
  # We're about twice as slow as GMP in these microbenchmarks:

  # 4.8 s vs 3.9 s GMP
  #var a = initBigInt(1337)
  #var b = initBigInt(42)
  #var c = initBigInt(0)

  #for i in 0..200000:
  #  c = a + b
  #  b = a + c
  #  a = b + c
  #c += c

  # 1.0 s vs 0.7 s GMP
  #var a = initBigInt(0xFFFFFFFF'u32)
  #var b = initBigInt(0xFFFFFFFF'u32)
  #var c = initBigInt(0)

  #for i in 0..20_000:
  #  c = a * b
  #  a = c * b

  #var a = initBigInt(@[0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32])
  #var b = initBigInt(@[0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32])
  #var c = initBigInt(0)

  # 0.5 s vs 0.2 s GMP
  #var a = initBigInt(@[0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32])
  #var b = initBigInt(@[0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32])
  #var c = initBigInt(0)
  #for i in 0..10_000_000:
  #  c = a * b

  #var a = initBigInt(1000000000)
  #var b = initBigInt(1000000000)
  #var c = a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a
  #echo c.toString()

  #var a = initBigInt(@[0xFEDCBA98'u32, 0xFFFFFFFF'u32, 0x12345678'u32, 0xFFFFFFFF'u32])
  #var b = initBigInt(0)
  #echo a
  #b = a shl 205
  #echo b
  #a = a shl 205
  #echo a
  #for i in 0..100000000:
  #  shiftLeft(b, a, 24)
  #echo b
  #shiftLeft(a, b, 24)
  #echo a
  #shiftRight(a, b, 20000)
  #echo a

  #echo a
  #c = a * b
  #echo c
  #for i in 0..50000:
  #  a *= b
  #echo a

  #echo cmp(a,a)
  #echo cmp(a,b)
  #echo cmp(b,a)
  #echo cmp(a,c)
  #echo cmp(c,a)
  #echo cmp(b,c)
  #echo cmp(b,b)
  #echo cmp(c,c)

  #for i in 0..1000000:
  #  var x = initBigInt("0000111122223333444455556666777788889999")
  #var x = initBigInt("0000111122223333444455556666777788889999", 16)
  #var x = initBigInt("11", 16)
  #echo x
  #var y = initBigInt("-0000110000000000000000000000000000000000", 16)
  #var y = initBigInt("-11", 16)
  #echo y

  #var a = initBigInt("222222222222222222222222222222222222222222222222222222222222222222222222222222", 16)
  #var b = initBigInt("1111111111111111111111111111111111111111111111111111111111111111111111111", 16)
  #var q = initBigInt(0)
  #var r = initBigInt(0)
  #division(q,r,a,b)
  #echo q.limbs
  #echo r.limbs

  var a = initBigInt("1234567890000000", 10)
  echo a
