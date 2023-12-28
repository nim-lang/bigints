import ../bigints
import std/sequtils
import std/options
import std/random

# workaround for https://github.com/nim-lang/Nim/issues/16360
proc rand(r: var Rand, max: uint64): uint64 =
  if max == 0:
    return 0
  elif max == uint64.high:
    return r.next()
  else:
    var iters = 0
    while true:
      let x = next(r)
      # avoid `mod` bias
      if x <= uint64.high - (uint64.high mod max) or iters > 20:
        return x mod (max + 1)
      else:
        inc iters

func rand*(r: var Rand, x: Slice[BigInt]): BigInt =
  ## Return a random `BigInt`, within the given range, using the given state.
  assert(x.a <= x.b, "invalid range")
  if x.a == x.b:
    return x.a
  let
    spread = x.b - x.a
    # number of bits *not* including leading bit
    nbits = spread.fastLog2
    # number of limbs to generate completely randomly
    nFullLimbs = max(nbits div 32 - 1, 0)
    # highest possible value of the top two limbs.
    hi64Max = (spread shr (nFullLimbs * 32)).toInt[:uint64].get()
  while true:
    # these limbs can be generated completely arbitrarily
    var limbs = newSeqWith(nFullLimbs, uint32(r.next() and uint32.high)) # work around https://github.com/nim-lang/Nim/issues/16360
    # generate the top two limbs more carefully. This all but guarantees
    # that the entire number is in the correct range
    let hi64 = r.rand(hi64Max)
    limbs.add(uint32(hi64 and uint32.high))
    limbs.add(uint32(hi64 shr 32))
    result = initBigInt(limbs)
    if result <= spread:
      break
  result += x.a

func rand*(r: var Rand, max: BigInt): BigInt =
  ## Return a random non-negative `BigInt`, up to `max`, using the given state.
  rand(r, 0.initBigInt..max)

# backwards compatibility with 1.4
when not defined(randState):
  var state = initRand(777)
  proc randState(): var Rand = state

proc rand*(x: Slice[BigInt]): BigInt = rand(randState(), x)
  ## Return a random `BigInt`, within the given range.

proc rand*(max: BigInt): BigInt = rand(randState(), max)
  ## Return a random `BigInt`, up to `max`.
