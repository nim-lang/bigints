## Pollard's p-1
##
## This file illustrates how to find a factor of an integer using
## [Pollard's p-1 algorithm](https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm).

import bigints
import std/options
import std/strformat


func pollardPMinus1(
  n: BigInt,
  searchLimit: BigInt,
  powerBase: BigInt = 2.initBigInt): Option[BigInt] =
  ## Performs Pollard's p-1 algorithm to find a non-trivial factor of `n`.
  var
    curPow = powerBase mod n

  for k in 1.initBigInt .. searchLimit:
    curPow = curPow.powmod(k, n)
    let divisor = gcd(curPow-1.initBigInt, n)
    if divisor != 1.initBigInt and divisor != n:
      return some(divisor)

  none(BigInt)


proc main() =
  const someNum = "52541208898777".initBigInt
  let result = pollardPMinus1(someNum, "1000000".initBigInt)
  if result.isSome():
    let factor = result.get()
    echo fmt"{factor} is a factor of {someNum}"
    assert someNum mod factor == 0.initBigInt
  else:
    echo fmt"could not find a factor of {someNum}"


main()
