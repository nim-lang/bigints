# BigInt to string and string to BigInt functions
import std/[options, math, algorithm]
include increments

func toInt*[T: SomeInteger](x: BigInt): Option[T] =
  ## Converts a `BigInt` number to an integer, if possible.
  ## If the `BigInt` doesn't fit in a `T`, returns `none(T)`;
  ## otherwise returns `some(x)`.
  runnableExamples:
    import std/options
    let
      a = 44.initBigInt
      b = 130.initBigInt
    assert toInt[int8](a) == some(44'i8)
    assert toInt[int8](b) == none(int8)
    assert toInt[uint8](b) == some(130'u8)
    assert toInt[int](b) == some(130)

  if x.isZero:
    return some(default(T)) # default(T) is 0
  when T is SomeSignedInt:
    # T is signed
    when sizeof(T) == 8:
      if x.limbs.len > 2:
        result = none(T)
      elif x.limbs.len == 2:
        if x.isNegative:
          if x.limbs[1] > uint32(int32.high) + 1 or (x.limbs[1] == uint32(int32.high) + 1 and x.limbs[0] > 0):
            result = none(T)
          else:
            let value = not T(x.limbs[1].uint64 shl 32 + x.limbs[0] - 1)
            result = some(value)
        else:
          if x.limbs[1] > uint32(int32.high):
            result = none(T)
          else:
            let value = T(x.limbs[1].uint64 shl 32 + x.limbs[0])
            result = some(value)
      else:
        if x.isNegative:
          result = some(not T(x.limbs[0] - 1))
        else:
          result = some(T(x.limbs[0]))
    else:
      if x.limbs.len > 1:
        result = none(T)
      else:
        if x.isNegative:
          if x.limbs[0] > uint32(T.high) + 1:
            result = none(T)
          else:
            result = some(not T(x.limbs[0] - 1))
        else:
          if x.limbs[0] > uint32(T.high):
            result = none(T)
          else:
            result = some(T(x.limbs[0]))
  else:
    # T is unsigned
    if x.isNegative:
      return none(T)
    when sizeof(T) == 8:
      if x.limbs.len > 2:
        result = none(T)
      elif x.limbs.len == 2:
        let value = T(x.limbs[1]) shl 32 + T(x.limbs[0])
        result = some(value)
      else:
        result = some(T(x.limbs[0]))
    else:
      if x.limbs.len > 1:
        result = none(T)
      elif x.limbs[0] > uint32(T.high):
        result = none(T)
      else:
        result = some(T(x.limbs[0]))

func calcSizes(): array[2..36, int] =
  for i in 2..36:
    var x = int64(i)
    while x <= int64(uint32.high) + 1:
      x *= i
      result[i].inc

const
  digits = "0123456789abcdefghijklmnopqrstuvwxyz"
  powers = {2, 4, 8, 16, 32}
  sizes = calcSizes() # `sizes[base]` is the maximum number of digits that fully fit in a `uint32`

func toString*(a: BigInt, base: range[2..36] = 10): string =
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

  let size = sizes[base]
  if base in powers:
    let
      bits = countTrailingZeroBits(base) # bits per digit
      mask = (1'u32 shl bits) - 1
      totalBits = 32 * a.limbs.len - countLeadingZeroBits(a.limbs[a.limbs.high])
    result = newStringOfCap((totalBits + bits - 1) div bits + 1)

    var
      acc = 0'u32
      accBits = 0 # the number of bits needed for acc
    for x in a.limbs:
      acc = acc or (x shl accBits)
      accBits += 32
      while accBits >= bits:
        result.add(digits[acc and mask])
        acc = acc shr bits
        if accBits > 32:
          acc = x shr (32 - (accBits - bits))
        accBits -= bits
    if acc > 0:
      result.add(digits[acc])
  else:
    let
      base = uint32(base)
      d = base ^ size
    var tmp = a

    tmp.isNegative = false
    result = newStringOfCap(size * a.limbs.len + 1) # estimate the length of the result

    while tmp > 0:
      var
        c: uint32
        tmpCopy = tmp
      unsignedDivRem(tmp, c, tmpCopy, d)
      for i in 1..size:
        result.add(digits[c mod base])
        c = c div base

  # normalize
  var i = result.high
  while i > 0 and result[i] == '0':
    dec i
  result.setLen(i+1)

  if a.isNegative:
    result.add('-')

  result.reverse()

func `$`*(a: BigInt): string =
  ## String representation of a `BigInt` in base 10.
  toString(a, 10)

func parseDigit(c: char, base: uint32): uint32 {.inline.} =
  result = case c
    of '0'..'9': uint32(ord(c) - ord('0'))
    of 'a'..'z': uint32(ord(c) - ord('a') + 10)
    of 'A'..'Z': uint32(ord(c) - ord('A') + 10)
    else: raise newException(ValueError, "Invalid input: " & c)

  if result >= base:
    raise newException(ValueError, "Invalid input: " & c)

func filterUnderscores(str: var string) {.inline.} =
  var k = 0 # the amount of underscores
  for i in 0 .. str.high:
    let c = str[i]
    if c == '_':
      inc k
    elif k > 0:
      str[i - k] = c
  str.setLen(str.len - k)

func initBigInt*(str: string, base: range[2..36] = 10): BigInt =
  ## Create a `BigInt` from a string. For invalid inputs, a `ValueError` exception is raised.
  runnableExamples:
    let
      a = initBigInt("1234")
      b = initBigInt("1234", base = 8)
    assert a == 1234.initBigInt
    assert b == 668.initBigInt

  if str.len == 0:
    raise newException(ValueError, "Empty input")

  let size = sizes[base]
  let base = base.uint32
  var first = 0
  var neg = false

  case str[0]
  of '-':
    if str.len == 1:
      raise newException(ValueError, "Invalid input: " & str)
    first = 1
    neg = true
  of '+':
    if str.len == 1:
      raise newException(ValueError, "Invalid input: " & str)
    first = 1
  else:
    discard
  if str[first] == '_':
    raise newException(ValueError, "A number can not begin with _")
  if str[^1] == '_':
    raise newException(ValueError, "A number can not end with _")

  if base in powers:
    # base is a power of two, so each digit corresponds to a block of bits
    let bits = countTrailingZeroBits(base) # bits per digit
    var
      acc = 0'u32
      accBits = 0 # the number of bits needed for acc
    for i in countdown(str.high, first):
      if str[i] != '_':
        let digit = parseDigit(str[i], base)
        acc = acc or (digit shl accBits)
        accBits += bits
        if accBits >= 32:
          result.limbs.add(acc)
          accBits -= 32
          acc = digit shr (bits - accBits)
    if acc > 0:
      result.limbs.add(acc)
    result.normalize()
  else:
    var str = str
    filterUnderscores(str)
    let d = initBigInt(base ^ size)
    for i in countup(first, str.high, size):
      var num = 0'u32 # the accumulator in this block
      if i + size <= str.len:
        # iterator over a block of length `size`, so we can use `d`
        for j in countup(i, i + size - 1):
          if str[j] != '_':
            let digit = parseDigit(str[j], base)
            num = (num * base) + digit
        unsignedAdditionInt(result, result * d, num)
      else:
        # iterator over a block smaller than `size`, so we have to compute `mul`
        var mul = 1'u32 # the multiplication factor for num
        for j in countup(i, min(i + size - 1, str.high)):
          if str[j] != '_':
            let digit = parseDigit(str[j], base)
            num = (num * base) + digit
            mul *= base
        unsignedAdditionInt(result, result * initBigInt(mul), num)

  result.isNegative = neg
