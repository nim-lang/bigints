import bigints
import benchy
from std/math import `^`
import pidigits
import rc_combperm

block: # Binomial and permutations
  timeIt "Permutation 1000, 969":
    keep perm(1000, 969)

  timeIt "Binomial computation 1000, 969":
    keep comb(1000, 969)

block: # Power computation
  timeIt "Power computation of 5^4^3^2":
    keep 5.initBigInt.pow 4 ^ (3 ^ 2)
  timeIt "Powers of two":
    var power = 2.initBigInt
    for _ in 1 .. 128000:
      power = power * 2.initBigInt

block: # Pidigits example
  timeIt "Computation of 100 digits of Pi":
    var i = 0
    while i < 100:
      var d: int32 = findPiDigit()
      inc(i)
      eliminateDigit(d)
  timeIt "Computation of 1000 digits of Pi":
    var i = 0
    while i < 1000:
      var d: int32 = findPiDigit()
      inc(i)
      eliminateDigit(d)

