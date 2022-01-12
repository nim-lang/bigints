# Solution for http://rosettacode.org/wiki/Modular_exponentiation

import bigints

const
  zero = 0.initBigInt
  one = 1.initBigInt
  two = 2.initBigInt

proc powmod(b, e, m: BigInt): BigInt =
  assert e >= zero
  var e = e
  var b = b
  result = one
  while e > zero:
    if e mod two == one:
      result = (result * b) mod m
    e = e div two
    b = (b.pow 2) mod m

var
  a = initBigInt("2988348162058574136915891421498819466320163312926952423791023078876139")
  b = initBigInt("2351399303373464486466122544523690094744975233415544072992656881240319")
  res = powmod(a, b, initBigInt(10).pow(40))

echo res
doAssert("1527229998585248450016808958343740453059".initBigInt == res)
