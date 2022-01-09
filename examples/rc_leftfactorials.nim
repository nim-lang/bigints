import iterutils
import bigints

const
  one = 1.initBigInt
  zero = 0.initBigInt

proc lfact: iterator: BigInt =
  result = iterator: BigInt =
    yield zero
    var
      fact = one
      sum = zero
      n = one
    while true:
      sum += fact
      fact *= n
      n += one
      yield sum

echo "first 11:"
for i in lfact().slice(last = 10):
  echo "  ", i

echo "20 through 110 (inclusive) by tens:"
for i in lfact().slice(20, 110, 10):
  echo "  ", i

echo "Digits in 1,000 through 10,000 (inclusive) by thousands:"
for i in lfact().slice(1_000, 10_000, 1_000):
  echo "  ", ($i).len
