import std/random
import ../bigints

const zero = initBigInt(0)
type
  RandomMode* = enum
    Limbs, Bits

proc randomizeBigInt(container: var seq[uint32], number: Natural, mode: RandomMode = Limbs) =
  case mode
  of Limbs:
    if number == 0:
      raise newException(ValueError, "A Bigint must have at least one limb !")
    # result.limbs.setLen(number)
    for i in 0 ..< number-1:
      container[i] = rand(uint32)
    var word = rand(uint32)
    # Bigint's last limb can be zero, iff there is only one limb
    # We can't normalize instead, since we need no less than number limbs
    if number != 1:
      while word == 0: # Very low probability
        word = rand(uint32)
    container[number-1] = word

  of Bits: # unit == Bits
    if number == 0:
      container = @[]
    let
      remainder = number mod 32
      n_limbs = (if remainder == 0: number shr 5 else: number shr 5 + 1)
      remainingBits  = (if remainder == 0: 32 else: remainder)
    # result.limbs.setLen(n_limbs)
    # mask ensures only remainingBits bits can be set to 1
    # mask2 ensures the first bit is set to 1
    var
      mask: uint32 = 0xFFFF_FFFF'u32
      mask2: uint32 = 0x8000_0000'u32
    if remainingBits != 32:
      mask = 1'u32 shl remainingBits - 1
      mask2 = 1'u32 shl (remainingBits-1)
    for i in 0 ..< container.high:
      container[i] = rand(uint32)
    let word = rand(uint32)
    container[container.high] = word and mask or mask2

proc initRandomBigInt*(number: Natural, mode: RandomMode = Limbs): BigInt =
  ## Initializes a `BigInt` whose value is chosen randomly with exactly
  ## `number` bits or limbs, depending on the value of `unit`. By default, the 
  ## `BigInt` is chosen with `number` limbs chosen randomly.
  ## Generates only positive bigints.
  var limbs: seq[uint32]
  let
    remainder = number mod 32
    n_limbs = (if remainder == 0: number shr 5 else: number shr 5 + 1)
  case mode
  of Limbs:
    limbs.setLen(number)
  of Bits:
    if number == 0:
      return zero
    let
      remainder = number mod 32
      len_limbs = (if remainder == 0: number shr 5 else: number shr 5 + 1)
    limbs.setLen(len_limbs)
  randomizeBigInt(limbs, number, mode)
  result = initBigInt(limbs, false)

