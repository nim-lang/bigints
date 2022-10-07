import bigints
import bigints/random
import std/options

block: # check uniformity
  let lo = pow(10'bi, 90)
  let hi = pow(10'bi, 100)
  var total = 0'bi
  let trials = 1000
  let nbuckets = 33
  var buckets = newSeq[int](nbuckets)
  for x in 0..trials:
    let r = rand(lo..hi)
    doAssert(lo <= r)
    doAssert(r <= hi)
    total += r
    let iBucket = (r-lo) div ((hi-lo) div initBigInt(nbuckets))
    buckets[iBucket.toInt[:int]().get()] += 1
  for x in buckets:
    doAssert(trials/nbuckets*0.5 < float(x))
    doAssert(float(x) < trials/nbuckets*1.5)

