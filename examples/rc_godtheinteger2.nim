# Solution for http://rosettacode.org/wiki/9_billion_names_of_God_the_integer#Python
import bigints

var p = @[1.initBigInt]
const
  zero = 0.initBigInt

proc partitions(n: int): BigInt =
  p.add zero

  for k in 1..n:
    var d = n - k * (3 * k - 1) div 2
    if d < 0:
      break

    if (k and 1) != 0:
      p[n] += p[d]
    else:
      p[n] -= p[d]

    d -= k
    if d < 0:
      break

    if (k and 1) != 0:
      p[n] += p[d]
    else:
      p[n] -= p[d]

  result = p[p.high]

const ns = [23, 123, 1234, 12345]
for i in 1 .. max(ns):
  let p = partitions(i)
  if i in ns:
    echo i,": ",p
