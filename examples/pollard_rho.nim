## Pollard's rho algorithm
##
## This file illustrates how to find a factor of an integer using
## [Pollard's rho algorithm](https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm).

import bigints
import std/options
import std/strformat


func pollardRho(
  n: BigInt,
  polynomial: proc(x: BigInt): BigInt {.noSideEffect.},
  initialValue: BigInt = 2.initBigInt): Option[BigInt] =
  ## Performs Pollard's rho algorithm to find a non-trivial factor of `n`.
  func polynomialMod(x: BigInt): BigInt =
    polynomial(x) mod n

  var
    turtle = initialValue
    hare = initialValue
    divisor = 1.initBigInt

  while divisor == 1.initBigInt:
    turtle = polynomialMod(turtle)
    hare = polynomialMod(polynomialMod(hare))
    divisor = gcd(turtle - hare, n)

  if divisor != n:
    some(divisor)
  else:
    none(BigInt)


func somePolynomial(x: BigInt): BigInt =
  x * x + 1.initBigInt


proc main() =
  const someNum = "44077431694086786329".initBigInt
  let result = pollardRho(someNum, somePolynomial)
  if result.isSome():
    let factor = result.get()
    echo fmt"{factor} is a factor of {someNum}"
    assert someNum mod factor == 0.initBigInt
  else:
    echo fmt"could not find a factor of {someNum}"


main()
