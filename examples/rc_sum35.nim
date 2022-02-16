import bigints

const
  one = 1.initBigInt
  two = 2.initBigInt
  ten = 10.initBigInt

proc sumMults(first: int32, limit: BigInt): BigInt =
  var last = limit - one
  var first = first.initBigInt
  last -= last mod first
  (last div first) * (last + first) div two

proc sum35(n: BigInt): BigInt =
  result = sumMults(3, n)
  result += sumMults(5, n)
  result -= sumMults(15, n)

var x = one
while x < "1000000000000000000000000000000".initBigInt:
  echo sum35 x
  x *= ten
