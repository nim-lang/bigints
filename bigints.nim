import unsigned, strutils
#import nimprof

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

template addParts(toAdd) =
  tmp += toAdd
  a.limbs[i] = uint32(tmp)
  tmp = tmp shr 32

# TODO: Negative numbers
proc addition*(a: var BigInt, b, c: BigInt) =
  var tmp: uint64

  let bl = b.limbs.len
  let cl = c.limbs.len
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

proc `+=` *(a: var BigInt, b: BigInt) =
  let c = a
  addition(a, c, b)

template optAdd{x = y + z}(x,y,z: BigInt) = addition(x, y, z)

template realMultiplication(a: var BigInt, b, c: BigInt, bl, cl) =
  var tmp: uint64
  a.limbs.setLen(bl + cl)

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
    {.unroll: 4.}
    for i in 0 .. < bl:
      {.unroll: 4.}
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

proc multiplication*(a: var BigInt, b, c: BigInt) =
  let bl = b.limbs.len
  let cl = c.limbs.len

  if cl > bl:
    realMultiplication(a, c, b, cl, bl)
  else:
    realMultiplication(a, b, c, bl, cl)

proc `*` *(a, b: BigInt): BigInt=
  result = initBigInt(0)
  multiplication(result, a, b)

proc `*=` *(a: var BigInt, b: BigInt) =
  let c = a
  multiplication(a, c, b)

template optMul{x = `*`(y, z)}(x,y,z: BigInt) = multiplication(x, y, z)

proc `$`*(a: BigInt) : string =
  result = newStringOfCap(8 * a.limbs.len)
  #result.add("0x")
  for i in countdown(a.limbs.len - 1, 0):
    result.add(toLower(toHex(int(A.limbs[i]), 8)))

when isMainModule:
  #var a = initBigInt(1337)
  #var b = initBigInt(42)
  #var c = initBigInt(0)

  #echo a
  #echo b
  #add(c, a, b)
  #echo c

  #for i in 0..199999:
  #  c = a + b
  #  b = a + c
  #  a = b + c

  #c += c

  var a = initBigInt(@[0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32])
  var b = initBigInt(@[0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32, 0xFFFFFFFF'u32])
  var c = initBigInt(0)
  #for i in 0..20_000:
  #  multiplication(c,a,b)
  #  multiplication(a,c,b)
  #  #multiplication(b,a,c);
  for i in 0..1_000_000:
    multiplication(c,a,b)
    #c = a * b
  echo c
