import bigints, unittest

const
  zero = initBigInt(0)
  one = initBigInt(1)

test "initBigInt":
  let a = 1234567.initBigInt
  check $a == "1234567"

  let b = -1234567.initBigInt
  check $b == "-1234567"

  let c = 123456789012345678.initBigInt
  check $c == "123456789012345678"

  let d = -123456789012345678.initBigInt
  check $d == "-123456789012345678"

  let e = int64.high.initBigInt
  check $e == $int64.high

  let f = int64.low.initBigInt
  check $f == $int64.low

  let g = (1'u64 shl 63).initBigInt
  check $g == $(1'u64 shl 63)

  let h = 1234567.initBigInt
  let i = h.initBigInt
  check $h == $i

  # test various bit patterns at power-of-two boundaries
  block:
    proc chk[T](v: T) =
      check $v == $(v.initBigInt)
    for bits in 0 .. 63:
      let x = 1'u64 shl bits
      let start = if x >= 8'u64: x - 8 else: 0'u64
      let stop = x + 8
      for vv in start .. stop:
        for v in [vv, not vv]:
          chk cast[int](v)
          chk v.uint
          chk cast[int64](v)
          chk v.uint64
          chk (v and int32.high.uint64).int32
          chk (v and uint32.high).uint32


when (NimMajor, NimMinor) >= (1, 5):
  test "literals":
    # workaround
    include "tliterals"


test "range of bigint (https://github.com/def-/nim-bigints/issues/1)":
  let two = 2.initBigInt
  let n = "123".initBigInt
  var result = 1.initBigInt
  for i in two .. n:
    result *= i
  check result == initBigInt("12146304367025329675766243241881295855454217088483382315328918161829235892362167668831156960612640202170735835221294047782591091570411651472186029519906261646730733907419814952960000000000000000000000000000")

test "multiple multiplications (https://github.com/def-/nim-bigints/issues/3)":
  let nums = [ "68855123440532288245010625",
               "201850901852714536181760000",
               "435980903974422631450250625",
               "824199001261152424427520000",
               "11527258048987096618327125",
               "18960243520191483654144000" ]

  var total = 1.initBigInt

  for e in items(nums):
    let bigInt = e.initBigInt
    total *= bigInt

  check total == initBigInt("1091531901753858845417645933677882391421406095571139520376889755608568225321090455009925801178698945969179844505331560015898829746339840000000000000000000000")

test "negative bigint (https://github.com/def-/nim-bigints/issues/4)":
  let x = -initBigInt(1)
  check x == initBigInt(-1)

test "off by one in division (https://github.com/def-/nim-bigints/issues/5)":
  block:
    var x = initBigInt("815915283247897734345611269596115894272000000000")
    var y = initBigInt("5919012181389927685417441689600000000")
    check x div y == initBigInt("137846528820")

  block:
    var x = initBigInt("815915283247897734345611269596115894272000000000")
    var y = initBigInt("20000000000")
    check x div y == initBigInt("40795764162394886717280563479805794713")

test "negative zero flags (https://github.com/def-/nim-bigints/issues/16)":
  let
    a = initBigInt("828478292990482")
    b = initBigInt(9283)
    c = initBigInt("-828478292990482")
    d = initBigInt(-9283)
    e = initBigInt(0)
  check b + d == e
  check a + c == e

  check d + b == e
  check c + a == e

  check b - b == e
  check d - d == e

  check d * e == e
  check b * e == e
  check e div d == e

test "validate digits in string parsing (https://github.com/def-/nim-bigints/issues/22)":
  check initBigInt("1", 2) == initBigInt(1)
  check initBigInt("z", 36) == initBigInt(35)
  expect ValueError:
    discard initBigInt("2", 2)
  expect ValueError:
    discard initBigInt("z", 35)

test "empty limbs when uninitialized (https://github.com/def-/nim-bigints/issues/26)":
  # reported issue has an example about multiplication and it is due to a call to a.limbs[0] for an uninitialized a: BigInt
  # besides multiplication, one could look at appearances of [0] in source to find possible failures
  # failures bound to reaching a line with [0] are fatal
  # besides appearances of [0], also logic implemented through a.limbs.len might (and indeed does) show error
  # logic around sign might also play a role
  var
    zeroEmpty: BigInt # should be treated as zero, same with -zeroEmpty
  let
    bigOne: BigInt = initBigInt(@[0.uint32, 1])

  # this came up in the above testing and can be though as secondary effect of unitialization (fix in negate?)
  check $zero == "0" # ok
  check $zeroEmpty == "0" # ok
  check $(-zeroEmpty) == "0" # error: fixed

  # unsignedCmp(a, b: BigInt) has no [0] but it has logic with limbs.len
  check zeroEmpty < one # ok
  check zeroEmpty > -one # ok
  check -zeroEmpty < one # ok
  check -zeroEmpty > -one # ok
  check not (zeroEmpty < zero) # error: fixed
  check not (zeroEmpty > zero) # ok
  check zeroEmpty == zero # error: fixed
  check -zeroEmpty == zero # error: fixed

  # proc unsignedAddition(a: var BigInt, b, c: BigInt)
  check zeroEmpty + one == one # ok
  check one + zeroEmpty == one # ok
  check -zeroEmpty + one == one # ok
  check one + -zeroEmpty == one # ok
  check zeroEmpty + zeroEmpty == zero # ok
  check -zeroEmpty + zeroEmpty == zero # ok
  check -zeroEmpty + -zeroEmpty == zero # ok
  check zeroEmpty + -zeroEmpty == zero # ok
  check bigOne + zeroEmpty == bigOne # ok
  check bigOne + -zeroEmpty == bigOne # ok
  check zeroEmpty + bigOne == bigOne # ok
  check -zeroEmpty + bigOne == bigOne # ok
  check -bigOne + zeroEmpty == -bigOne # ok
  check -bigOne + -zeroEmpty == -bigOne # ok
  check zeroEmpty + -bigOne == -bigOne # ok
  check -zeroEmpty + -bigOne == -bigOne # ok

  # proc unsignedSubtraction(a: var BigInt, b, c: BigInt)
  check zeroEmpty - one == -one # ok
  check one - zeroEmpty == one # ok
  check -zeroEmpty - one == -one # ok
  check one - -zeroEmpty == one # ok
  check zeroEmpty - zeroEmpty == zero # ok
  check -zeroEmpty - zeroEmpty == zero # ok
  check -zeroEmpty - -zeroEmpty == zero # ok
  check zeroEmpty - -zeroEmpty == zero # ok
  check bigOne - zeroEmpty == bigOne # ok
  check bigOne - -zeroEmpty == bigOne # ok
  check zeroEmpty - bigOne == -bigOne # ok
  check -zeroEmpty - bigOne == -bigOne # ok
  check -bigOne - zeroEmpty == -bigOne # ok
  check -bigOne - -zeroEmpty == -bigOne # ok
  check zeroEmpty - -bigOne == bigOne # ok
  check -zeroEmpty - -bigOne == bigOne # ok

  # multiplication
  check zeroEmpty * one == zero
  check -zeroEmpty * one == zero
  check one * zeroEmpty == zero
  check one * -zeroEmpty == zero

  # https://github.com/def-/nim-bigints/issues/26
  block:
    var
      a: BigInt
      b: BigInt = 12.initBigInt

    check a*b == 0.initBigInt

  # division does not have issues, but let's add some checks
  check zeroEmpty div one == zero
  check -zeroEmpty div one == zero
  check zeroEmpty mod one == zero
  check -zeroEmpty mod one == zero

test "shift left":
  let a63 = "9223372036854775808".initBigInt
  let a64 = "18446744073709551616".initBigInt
  let a65 = "36893488147419103232".initBigInt
  let a128 = "340282366920938463463374607431768211456".initBigInt
  let one = 1.initBigInt

  check one shl 63 == a63
  check one shl 64 == a64
  check one shl 65 == a65
  check one shl 128 == a128

test "bitwise operations":
  let
    a = "123456789123456789123456789".initBigInt
    b = 567.initBigInt
    c = 1234.initBigInt
    d = "340282366920938463463374607431768211456".initBigInt
    e = 1.initBigInt
    f = 0.initBigInt

  check (a and b) == 533.initBigInt
  check (a and c) == 1040.initBigInt
  check (b and c) == 18.initBigInt
  check (a and d) == 0.initBigInt
  check (b and d) == 0.initBigInt
  check (a and e) == 1.initBigInt
  check (d and e) == 0.initBigInt

  check (a or b) == "123456789123456789123456823".initBigInt
  check (a or c) == "123456789123456789123456983".initBigInt
  check (b or c) == 1783.initBigInt
  check (a or d) == "340282366921061920252498064220891668245".initBigInt
  check (b or d) == "340282366920938463463374607431768212023".initBigInt
  check (a or e) == a
  check (d or e) == (d + e)

  check (a xor b) == "123456789123456789123456290".initBigInt
  check (a xor c) == "123456789123456789123455943".initBigInt
  check (b xor c) == 1765.initBigInt
  check (a xor d) == "340282366921061920252498064220891668245".initBigInt
  check (b xor d) == "340282366920938463463374607431768212023".initBigInt
  check (a xor e) == (a - e)
  check (d xor e) == (d + e)
  check (d xor d) == f
  check (d xor f) == d

test "self-multiplication":
  var a = 12.initBigInt
  a *= a
  check a == 144.initBigInt
  a *= a
  check a == 20736.initBigInt
  a *= a
  check a == 429981696.initBigInt
  a *= a
  check a == "184884258895036416".initBigInt
  var b = zero
  b *= b
  check b == zero
  var c = one
  c *= c
  check c == one
  a *= b
  check a == zero
