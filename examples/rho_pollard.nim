## Rho-Pollard
##
## This file illustrates how to find a factor of an integer using the
## [rho-Pollard algorithm](https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm).

import bigints
import std/options
import std/strformat


func rhoPollard(
  n: BigInt,
  nextIteration: proc(x: BigInt): BigInt {.noSideEffect.},
  initialValue: BigInt = 2.initBigInt): Option[BigInt] =
  ## performs the rho-Pollard search
  func nextIterationMod(x: BigInt): BigInt =
    return nextIteration(x) mod n
  var
    turtle = initialValue
    hare = initialValue
    divisor = 1.initBigInt

  while divisor == 1.initBigInt:
    turtle = nextIterationMod(turtle)
    hare = nextIterationMod(nextIterationMod(hare))
    divisor = gcd(turtle-hare, n)

  if divisor != n:
    return some(divisor)


func somePoly(number: BigInt): BigInt =
  return number*number+1.initBigInt


proc main() =
  const someNum = "44077431694086786329".initBigInt
  let result = rhoPollard(someNum, somePoly)
  if result.isSome():
    echo fmt"{result.get()} is a factor of {someNum}"
    assert someNum mod result.get() == 0.initBigInt
  else:
    echo fmt"could not find a factor of {someNum} using rho-Pollard algorithm"


main()
