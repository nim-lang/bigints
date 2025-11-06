import bigints
import bigints/random
import std/options

block: # check uniformity
  let lo = pow(10.initBigInt, 90)
  let hi = pow(10.initBigInt, 100)
  var total = 0.initBigInt
  let trials = 1000
  let nbuckets = 33
  var buckets = newSeq[int](nbuckets)
  for x in 0..trials:
    let r = rand(lo..hi)
    doAssert(lo <= r)
    doAssert(r <= hi)
    total += r
    let iBucket = (r - lo) div ((hi - lo) div initBigInt(nbuckets))
    buckets[iBucket.toInt[:int]().get()] += 1
  let expected = trials / nbuckets
  for x in buckets:
    doAssert(expected * 0.5 < float(x))
    doAssert(float(x) < expected * 1.5)

block: # single element range
  let x = 1234567890.initBigInt
  for _ in 1..100:
    doAssert rand(x..x) == x
