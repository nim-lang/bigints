import bigints

const
  one = 1.initBigInt
  zero = 0.initBigInt

iterator lfact: BigInt =
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

var i = 0
for n in lfact():
  if i == 0:
    echo "first 11:"
  if i == 20:
    echo "20 through 110 (inclusive) by tens:"
  if i == 1000:
    echo "Digits in 1,000 through 10,000 (inclusive) by thousands:"

  if i <= 10:
    echo i, ": ", n
  elif i <= 110 and i mod 10 == 0:
    echo i, ": ", n
  elif i >= 1000 and i <= 10_000 and i mod 1000 == 0:
    echo i, ": ", ($n).len
  elif i > 10_000:
    break
  inc i

