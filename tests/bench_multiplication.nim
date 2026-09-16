import bigints
import std/[math, random, sequtils, strutils, times]

proc main() =
  randomize()
  # Pick a number in 0..100.
  let limit = 10^9
  let limbs = 10000
  let randomBigInt = toSeq(1..limbs).mapIt(rand(limit)).join("").initBigInt
  let randomBigInt2 = toSeq(1..limbs).mapIt(rand(limit)).join("").initBigInt
  let randomBigInt3 = toSeq(1..limbs).mapIt(rand(limit)).join("").initBigInt

  var
    n = 30
    totalTime = 0.0
    minTime = -1.0
    maxTime = 0.0

  for i in 1..n:
    if i mod (n div 10) == 0:
      echo "run: ", i
    let startTime = cpuTime()
    # Compute subproducts
    let prod1 = randomBigInt * randomBigInt2
    let prod1bis = randomBigInt2 * randomBigInt

    # Check commutativity of the product
    doAssert prod1 == prod1bis

    let prod2 = randomBigInt2 * randomBigInt3
    let prod3 = randomBigInt * randomBigInt3
    let product = prod2 * randomBigInt

    # Check associativity of the product
    doAssert prod1 * randomBigInt3 == product
    doAssert prod3 * randomBigInt2 == product
    let endTime = cpuTime()
    let time = endTime - startTime
    totalTime += time
    if minTime < 0 or time < minTime: minTime = time
    if time > maxTime: maxTime = time
  echo (avg: totalTime / n.float, min: minTime, max: maxTime)

main()
