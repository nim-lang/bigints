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
    let iBucket = (r-lo) div ((hi-lo) div initBigInt(nbuckets))
    buckets[iBucket.toInt[:int]().get()] += 1
  for x in buckets:
    doAssert(trials/nbuckets*0.5 < float(x))
    doAssert(float(x) < trials/nbuckets*1.5)

block: # check serialization roundtrip
  const
    trials = 1024
  var a, b: Bigint
  for x in 0..trials:
    a = rand(0.initBigInt..pow(2.initBigInt, x))
    for endian in [bigEndian, littleEndian]:
      b.fromBytes(a.toBytes(endian), endian)
      doAssert a == b
