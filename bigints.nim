import unsigned, strutils

type
  Flags = enum
    Negative

  BigInt* = tuple
    limbs: seq[uint32]
    flags: set[Flags]

const maxInt = int64(high uint32)

proc initBigInt*(val: uint32): BigInt =
  result.limbs = @[val]
  result.flags = {}

proc initBigInt*(vals: seq[uint32]): BigInt =
  result.limbs = vals
  result.flags = {}

template comparison(op, br) =
  result = op(a.limbs.len, b.limbs.len)

  if br:
    return

  for i in countdown(a.limbs.high, 0):
    result = op(a.limbs[i], b.limbs[i])

    if br:
      return

proc cmp*(a, b: BigInt): int64 =
  proc minus(x, y): int64 = int64(x) - int64(y)
  comparison(minus, result != 0)

proc `<` *(a, b: BigInt): bool =
  comparison(`<`, result)

proc `<=` *(a, b: BigInt): bool =
  comparison(`<=`, not result)

proc `==` *(a, b: BigInt): bool =
  comparison(`==`, not result)

template addParts(toAdd) =
  tmp += toAdd
  a.limbs[i] = uint32(tmp)
  tmp = tmp shr 32

# TODO: Negative numbers
# This should also work even if a = b
proc addition(a: var BigInt, b, c: BigInt) =
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

proc `+` *(a, b: BigInt): BigInt=
  result = initBigInt(0)
  addition(result, a, b)

template `+=` *(a: var BigInt, b: BigInt) =
  let c = a
  addition(a, c, b)

template optAdd{x = y + z}(x,y,z: BigInt) = addition(x, y, z)

template realMultiplication(a: BigInt, b, c: BigInt, bl, cl) =
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

# This doesn't work when a = b
proc multiplication(a: var BigInt, b, c: BigInt) =
  let
    bl = b.limbs.len
    cl = c.limbs.len
  var tmp: uint64

  a.limbs.setLen(bl + cl)

  if cl > bl:
    realMultiplication(a, c, b, cl, bl)
  else:
    realMultiplication(a, b, c, bl, cl)

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

#proc toString*(a: BigInt, base: range[2..36] = 10): string =
#  const digits = "0123456789abcdefghijklmnopqrstuvwxyz"
#  result = ""
#  for l in a.limbs:
#    echo(uint64(l mod 1000000))

proc `$`*(a: BigInt) : string =
  result = newStringOfCap(8 * a.limbs.len)
  #result.add("0x")
  for i in countdown(a.limbs.len - 1, 0):
    result.add(toLower(toHex(int(A.limbs[i]), 8)))

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
