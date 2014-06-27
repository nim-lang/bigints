import unsigned

type
  Flags* = enum
    Negative

  BigInt* = tuple
    limbs: seq[uint32]
    flags: set[Flags]

const maxInt = int64(high uint32)

proc init*(val: uint32): BigInt =
  result.limbs = @[val]
  result.flags = {}

proc add*(a: var BigInt, b, c: BigInt) =
  var tmp: uint64

  let bl = b.limbs.len
  let cl = c.limbs.len
  var m = if bl < cl: bl else: cl

  a.limbs.setLen(if bl < cl: cl else: bl)

  for i in 0 .. < m:
    tmp += uint64(b.limbs[i]) + uint64(c.limbs[i])
    a.limbs[i] = uint32(tmp)
    tmp = tmp shr 32

  if bl < cl:
    for i in m .. < cl:
      tmp += uint64(c.limbs[i])
      a.limbs[i] = uint32(tmp)
      tmp = tmp shr 32
  else:
    for i in m .. < bl:
      tmp += uint64(b.limbs[i])
      a.limbs[i] = uint32(tmp)
      tmp = tmp shr 32

  if tmp > 0'u64:
    a.limbs.add(uint32(tmp))

proc `$`*(A:BigInt) : string =
  result = ""
  const HexChars = "0123456789ABCDEF"
  for d in A.limbs:
    var tmp : int = int(d)
    for i in 0..8:
      let digit : int = int(tmp mod 16)
      let c : char = HexChars[digit]
      result = c&result
      tmp = tmp /% 16
  return "0x"&result

var a = init(high uint32)
var b = init(high uint32)
var c = init(0)

#echo a
#echo b
#add(c, a, b)
#echo c

for i in 0..99999:
  add(c, a, b)
  add(b, a, c)
  add(a, b, c)

#echo a.limbs
#echo b.limbs
#echo c
