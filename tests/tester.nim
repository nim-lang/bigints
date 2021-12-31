import bigints, std/unittest

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
    include tliterals

test "range of bigint (https://github.com/nim-lang/bigints/issues/1)":
  let two = 2.initBigInt
  let n = "123".initBigInt
  var result = 1.initBigInt
  for i in two .. n:
    result *= i
  check result == initBigInt("12146304367025329675766243241881295855454217088483382315328918161829235892362167668831156960612640202170735835221294047782591091570411651472186029519906261646730733907419814952960000000000000000000000000000")

test "multiple multiplications (https://github.com/nim-lang/bigints/issues/3)":
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

test "negative bigint (https://github.com/nim-lang/bigints/issues/4)":
  let x = -initBigInt(1)
  check x == initBigInt(-1)

test "off by one in division (https://github.com/nim-lang/bigints/issues/5)":
  block:
    var x = initBigInt("815915283247897734345611269596115894272000000000")
    var y = initBigInt("5919012181389927685417441689600000000")
    check x div y == initBigInt("137846528820")

  block:
    var x = initBigInt("815915283247897734345611269596115894272000000000")
    var y = initBigInt("20000000000")
    check x div y == initBigInt("40795764162394886717280563479805794713")

test "negative zero flags (https://github.com/nim-lang/bigints/issues/16)":
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

test "validate digits in string parsing (https://github.com/nim-lang/bigints/issues/22)":
  check initBigInt("1", 2) == initBigInt(1)
  check initBigInt("z", 36) == initBigInt(35)
  expect ValueError:
    discard initBigInt("2", 2)
  expect ValueError:
    discard initBigInt("z", 35)

test "empty limbs when uninitialized (https://github.com/nim-lang/bigints/issues/26)":
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

  # https://github.com/nim-lang/bigints/issues/26
  block:
    var
      a: BigInt
      b: BigInt = 12.initBigInt

    check a * b == 0.initBigInt

  # division does not have issues, but let's add some checks
  check zeroEmpty div one == zero
  check -zeroEmpty div one == zero
  check zeroEmpty mod one == zero
  check -zeroEmpty mod one == zero

test "shift":
  let
    x = "190485713846014693847".initBigInt
    y = "-190485713846014693847".initBigInt
    a63 = "9223372036854775808".initBigInt
    a64 = "18446744073709551616".initBigInt
    a65 = "36893488147419103232".initBigInt
    a128 = "340282366920938463463374607431768211456".initBigInt

  # shl
  check one shl 63 == a63
  check one shl 64 == a64
  check one shl 65 == a65
  check one shl 128 == a128
  check x shl 0 == x
  check x shl 1 == "380971427692029387694".initBigInt
  check x shl 7 == "24382171372289880812416".initBigInt
  check x shl 31 == "409064955661923745004158713856".initBigInt
  check x shl 32 == "818129911323847490008317427712".initBigInt
  check x shl 33 == "1636259822647694980016634855424".initBigInt
  check x shl 53 == "1715742779792629411365922910161076224".initBigInt
  check x shl 63 == "1756920606507652517238705060004942053376".initBigInt
  check x shl 64 == "3513841213015305034477410120009884106752".initBigInt
  check x shl 65 == "7027682426030610068954820240019768213504".initBigInt
  check y shl 0 == y
  check y shl 1 == "-380971427692029387694".initBigInt
  check y shl 7 == "-24382171372289880812416".initBigInt
  check y shl 31 == "-409064955661923745004158713856".initBigInt
  check y shl 32 == "-818129911323847490008317427712".initBigInt
  check y shl 33 == "-1636259822647694980016634855424".initBigInt
  check y shl 53 == "-1715742779792629411365922910161076224".initBigInt
  check y shl 63 == "-1756920606507652517238705060004942053376".initBigInt
  check y shl 64 == "-3513841213015305034477410120009884106752".initBigInt
  check y shl 65 == "-7027682426030610068954820240019768213504".initBigInt

  # shr
  check a63 shr 63 == one
  check a64 shr 64 == one
  check a65 shr 65 == one
  check a128 shr 128 == one
  check -one shr 1 == -one
  check -2.initBigInt shr 1 == -one
  check x shr 0 == x
  check x shr 1 == "95242856923007346923".initBigInt
  check x shr 7 == "1488169639421989795".initBigInt
  check x shr 31 == "88701822723".initBigInt
  check x shr 32 == "44350911361".initBigInt
  check x shr 33 == "22175455680".initBigInt
  check x shr 53 == "21148".initBigInt
  check x shr 63 == "20".initBigInt
  check x shr 64 == "10".initBigInt
  check x shr 65 == "5".initBigInt
  check y shr 0 == y
  check y shr 1 == "-95242856923007346924".initBigInt
  check y shr 7 == "-1488169639421989796".initBigInt
  check y shr 31 == "-88701822724".initBigInt
  check y shr 32 == "-44350911362".initBigInt
  check y shr 33 == "-22175455681".initBigInt
  check y shr 53 == "-21149".initBigInt
  check y shr 63 == "-21".initBigInt
  check y shr 64 == "-11".initBigInt
  check y shr 65 == "-6".initBigInt

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

test "self-addition/self-subtraction":
  # self-addition
  var a = zero
  a += a
  check a == zero
  a = 12.initBigInt
  a += a
  check a == 24.initBigInt
  a = 20736.initBigInt
  a += a
  check a == 41472.initBigInt
  a = "184884258895036416".initBigInt
  a += a
  check a == "369768517790072832".initBigInt

  # self-subtraction
  var b = zero
  b -= b
  check b == zero
  b = 12.initBigInt
  b -= b
  check b == zero
  b = 20736.initBigInt
  b -= b
  check b == zero
  b = "184884258895036416".initBigInt
  b -= b
  check b == zero

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

test "inc/dec":
  var x: BigInt

  x = 42.initBigInt
  x.inc
  check x == 43.initBigInt
  x.inc(int32.high)
  check x == "2147483690".initBigInt
  x.inc(int32.low)
  check x == 42.initBigInt
  x.inc(-42)
  check x == 0.initBigInt

  x = 42.initBigInt
  x.dec
  check x == 41.initBigInt
  x.dec(int32.high)
  check x == "-2147483606".initBigInt
  x.dec(int32.low)
  check x == 42.initBigInt
  x.dec(-42)
  check x == 84.initBigInt

  # edge cases

  x = 1.initBigInt
  x.inc(int32.low)
  check x == "-2147483647".initBigInt
  x = -1.initBigInt
  x.inc(2)
  check x == 1.initBigInt
  x = -1.initBigInt
  x.inc(-2)
  check x == -3.initBigInt

  x = 0.initBigInt
  x.dec(int32.low)
  check x == "2147483648".initBigInt
  x = 1.initBigInt
  x.dec(-2)
  check x == 3.initBigInt
  x = -1.initBigInt
  x.dec(-2)
  check x == 1.initBigInt
  x = 12.initBigInt
  x.dec(42)
  check x == -30.initBigInt

test "string conversion":
  for base in 2..36:
    # zero
    check zero.toString(base) == "0"
    check (-zero).toString(base) == "0" # no sign is produced for 0
    check "0".initBigInt(base) == zero
    check "-0".initBigInt(base) == zero
    check "00000".initBigInt(base) == zero
    check "-00000".initBigInt(base) == zero
    check "00000000000000000000000000000000000".initBigInt(base) == zero
    check "-00000000000000000000000000000000000".initBigInt(base) == zero

    # one
    check one.toString(base) == "1"
    check (-one).toString(base) == "-1"
    check "1".initBigInt(base) == one
    check "-1".initBigInt(base) == -one
    check "00001".initBigInt(base) == one
    check "-00001".initBigInt(base) == -one
    check "00000000000000000000000000000000001".initBigInt(base) == one
    check "-00000000000000000000000000000000001".initBigInt(base) == -one

  let a = initBigInt(uint64(uint32.high) + 1)
  check a.toString(base = 2) == "100000000000000000000000000000000"
  check a.toString(base = 3) == "102002022201221111211"
  check a.toString(base = 4) == "10000000000000000"
  check a.toString(base = 8) == "40000000000"
  check a.toString(base = 10) == "4294967296"
  check a.toString(base = 12) == "9ba461594"
  check a.toString(base = 16) == "100000000"
  check a.toString(base = 32) == "4000000"

  let b = initBigInt(0xfedcba9876543210'u64)
  check "1111111011011100101110101001100001110110010101000011001000010000".initBigInt(base = 2) == b
  check "11112100120110012201202221111221022102200".initBigInt(base = 3) == b
  check "33323130232221201312111003020100".initBigInt(base = 4) == b
  check "1773345651416625031020".initBigInt(base = 8) == b
  check "18364758544493064720".initBigInt(base = 10) == b
  check "833b81a74046633500".initBigInt(base = 12) == b
  check "fedcba9876543210".initBigInt(base = 16) == b
  check "ftn5qj1r58cgg".initBigInt(base = 32) == b

test "pow":
  let a = "14075287".initBigInt
  check pow(a, 0) == one
  check pow(a, 1) == a
  check pow(a, 2) == a * a
  check pow(a, 3) == a * a * a
  check pow(a, 4) == a * a * a * a
  check pow(a, 5) == a * a * a * a * a
  check pow(a, 6) == a * a * a * a * a * a
  check pow(a, 7) == a * a * a * a * a * a * a

  # special cases
  check pow(zero, 0) == one
  check pow(zero, 1) == zero
