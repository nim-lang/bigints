# Solution for https://rosettacode.org/wiki/9_billion_names_of_God_the_integer#Python
import bigints

var cache = @[@[1.initBigInt]]

proc cumu(n: int): seq[BigInt] =
  for l in cache.len .. n:
    var r = @[0.initBigInt]
    for x in 1..l:
      r.add r[r.high] + cache[l-x][min(x, l-x)]
    cache.add r
  result = cache[n]

proc row(n: int): seq[BigInt] =
  let r = cumu n
  result = @[]
  for i in 0 ..< n:
    result.add r[i+1] - r[i]

echo "rows:"
for x in 1..10:
  echo row x

echo "sums:"
# for 12345 this implementation is too slow, for a faster implementation see rc_godtheinteger2.nim
for x in [23, 123, 1234]:
  let c = cumu(x)
  echo x, " ", c[c.high]
