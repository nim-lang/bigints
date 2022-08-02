import bigints
import random

const
  zero = initBigInt(0)
  one = initBigInt(1)

proc main() =
  block:
    randomize()
    # Repeat probabilistic tests
    for nBits in [29, 32, 1037]:
      for _ in 1 .. 5:
        let a: BigInt = initRandomBigInt(nBits)
        assert (toString(a, 2)).len == nBits
        doAssert fastLog2(a) == (nBits - 1)

main()
