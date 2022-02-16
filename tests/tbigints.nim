import bigints
import std/options

const
  zero = initBigInt(0)
  one = initBigInt(1)

proc main() =
  block: # initBigInt
    let a = 1234567.initBigInt
    doAssert $a == "1234567"

    let b = -1234567.initBigInt
    doAssert $b == "-1234567"

    let c = 123456789012345678.initBigInt
    doAssert $c == "123456789012345678"

    let d = -123456789012345678.initBigInt
    doAssert $d == "-123456789012345678"

    let e = int64.high.initBigInt
    doAssert $e == $int64.high

    let f = int64.low.initBigInt
    doAssert $f == $int64.low

    let g = (1'u64 shl 63).initBigInt
    doAssert $g == $(1'u64 shl 63)

    let h = 1234567.initBigInt
    let i = h.initBigInt
    doAssert $h == $i
  
    block:
      # + sign
      let plus = "+1234567".initBigInt
      doAssert $plus == "1234567"

      # Trailing underscores
      # after 1 digit
      let a = "1_234_567".initBigInt
      doAssert $a == "1234567"
      # after 2 digits
      let b = "12_345_678".initBigInt
      doAssert $b == "12345678"
      # after 3 digits
      let c = "123_456_789".initBigInt
      doAssert $c == "123456789"

      # Trailing underscores and + sign
      # after 1 digit
      let a2 = "+1_234_567".initBigInt
      doAssert $a2 == "1234567"
      # after 2 digits
      let b2 = "+12_345_678".initBigInt
      doAssert $b2 == "12345678"
      # after 3 digits
      let c2 = "+123_456_789".initBigInt
      doAssert $c2 == "123456789"
      let d2 = "+123_456_789_012_345_678".initBigInt
      doAssert $d2 == "123456789012345678"

      # Trailing underscores and - sign
      let a3 = "-1_234_567".initBigInt
      doAssert $a3 == "-1234567"
      # after 2 digits
      let b3 = "-12_345_678".initBigInt
      doAssert $b3 == "-12345678"
      # after 3 digits
      let c3 = "-123_456_789".initBigInt
      doAssert $c3 == "-123456789"
      let d3 = "-123_456_789_012_345_678".initBigInt
      doAssert $d3 == "-123456789012345678"

    block:
      # Wrong formatting of numbers should raise a ValueError
      doAssertRaises(ValueError): discard "+".initBigInt
      doAssertRaises(ValueError): discard "-".initBigInt
      doAssertRaises(ValueError): discard "+@1".initBigInt
      doAssertRaises(ValueError): discard "+_1".initBigInt
      doAssertRaises(ValueError): discard "_123_345_678".initBigInt
      doAssertRaises(ValueError): discard "_12_3_345_678".initBigInt

    # test various bit patterns at power-of-two boundaries
    block:
      proc chk[T](v: T) =
        doAssert $v == $(v.initBigInt)
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
    block: # literals
      # workaround
      include tliterals

  block: # zero
    # see https://github.com/nim-lang/bigints/issues/26
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
    doAssert $zero == "0" # ok
    doAssert $zeroEmpty == "0" # ok
    doAssert $(-zeroEmpty) == "0" # error: fixed

    # unsignedCmp(a, b: BigInt) has no [0] but it has logic with limbs.len
    doAssert zeroEmpty < one # ok
    doAssert zeroEmpty > -one # ok
    doAssert -zeroEmpty < one # ok
    doAssert -zeroEmpty > -one # ok
    doAssert not (zeroEmpty < zero) # error: fixed
    doAssert not (zeroEmpty > zero) # ok
    doAssert zeroEmpty == zero # error: fixed
    doAssert -zeroEmpty == zero # error: fixed

    # proc unsignedAddition(a: var BigInt, b, c: BigInt)
    doAssert zeroEmpty + one == one # ok
    doAssert one + zeroEmpty == one # ok
    doAssert -zeroEmpty + one == one # ok
    doAssert one + -zeroEmpty == one # ok
    doAssert zeroEmpty + zeroEmpty == zero # ok
    doAssert -zeroEmpty + zeroEmpty == zero # ok
    doAssert -zeroEmpty + -zeroEmpty == zero # ok
    doAssert zeroEmpty + -zeroEmpty == zero # ok
    doAssert bigOne + zeroEmpty == bigOne # ok
    doAssert bigOne + -zeroEmpty == bigOne # ok
    doAssert zeroEmpty + bigOne == bigOne # ok
    doAssert -zeroEmpty + bigOne == bigOne # ok
    doAssert -bigOne + zeroEmpty == -bigOne # ok
    doAssert -bigOne + -zeroEmpty == -bigOne # ok
    doAssert zeroEmpty + -bigOne == -bigOne # ok
    doAssert -zeroEmpty + -bigOne == -bigOne # ok

    # proc unsignedSubtraction(a: var BigInt, b, c: BigInt)
    doAssert zeroEmpty - one == -one # ok
    doAssert one - zeroEmpty == one # ok
    doAssert -zeroEmpty - one == -one # ok
    doAssert one - -zeroEmpty == one # ok
    doAssert zeroEmpty - zeroEmpty == zero # ok
    doAssert -zeroEmpty - zeroEmpty == zero # ok
    doAssert -zeroEmpty - -zeroEmpty == zero # ok
    doAssert zeroEmpty - -zeroEmpty == zero # ok
    doAssert bigOne - zeroEmpty == bigOne # ok
    doAssert bigOne - -zeroEmpty == bigOne # ok
    doAssert zeroEmpty - bigOne == -bigOne # ok
    doAssert -zeroEmpty - bigOne == -bigOne # ok
    doAssert -bigOne - zeroEmpty == -bigOne # ok
    doAssert -bigOne - -zeroEmpty == -bigOne # ok
    doAssert zeroEmpty - -bigOne == bigOne # ok
    doAssert -zeroEmpty - -bigOne == bigOne # ok

    # multiplication
    doAssert zeroEmpty * one == zero
    doAssert -zeroEmpty * one == zero
    doAssert one * zeroEmpty == zero
    doAssert one * -zeroEmpty == zero

    # division does not have issues, but let's add some doAsserts
    doAssert zeroEmpty div one == zero
    doAssert -zeroEmpty div one == zero
    doAssert zeroEmpty mod one == zero
    doAssert -zeroEmpty mod one == zero

    # toInt
    for z in [zero, zeroEmpty, -zero, -zeroEmpty]:
      doAssert toInt[int](z) == some(0)
      doAssert toInt[int8](z) == some(0'i8)
      doAssert toInt[int16](z) == some(0'i16)
      doAssert toInt[int32](z) == some(0'i32)
      doAssert toInt[int64](z) == some(0'i64)
      doAssert toInt[uint](z) == some(0'u)
      doAssert toInt[uint8](z) == some(0'u8)
      doAssert toInt[uint16](z) == some(0'u16)
      doAssert toInt[uint32](z) == some(0'u32)
      doAssert toInt[uint64](z) == some(0'u64)

  block: # addition/subtraction
    block: # self-addition/self-subtraction
      # self-addition
      var a = zero
      a += a
      doAssert a == zero
      a = 12.initBigInt
      a += a
      doAssert a == 24.initBigInt
      a = 20736.initBigInt
      a += a
      doAssert a == 41472.initBigInt
      a = "184884258895036416".initBigInt
      a += a
      doAssert a == "369768517790072832".initBigInt

      # self-subtraction
      var b = zero
      b -= b
      doAssert b == zero
      b = 12.initBigInt
      b -= b
      doAssert b == zero
      b = 20736.initBigInt
      b -= b
      doAssert b == zero
      b = "184884258895036416".initBigInt
      b -= b
      doAssert b == zero

  block: # multiplication
    block:
      let
        a = "1780983279228119273110576463639172624".initBigInt
        b = "1843917749452418885995463656480858321".initBigInt
        c = "3283986680046702618742503890385314117448805445290098330749803441805804304".initBigInt
      doAssert a * b == c
      doAssert -a * b == -c
      doAssert a * -b == -c
      doAssert -a * -b == c

    block: # self-multiplication
      var a = 12.initBigInt
      a *= a
      doAssert a == 144.initBigInt
      a *= a
      doAssert a == 20736.initBigInt
      a *= a
      doAssert a == 429981696.initBigInt
      a *= a
      doAssert a == "184884258895036416".initBigInt
      var b = zero
      b *= b
      doAssert b == zero
      var c = one
      c *= c
      doAssert c == one
      a *= b
      doAssert a == zero

  block: # shift
    let
      x = "190485713846014693847".initBigInt
      y = "-190485713846014693847".initBigInt
      a63 = "9223372036854775808".initBigInt
      a64 = "18446744073709551616".initBigInt
      a65 = "36893488147419103232".initBigInt
      a128 = "340282366920938463463374607431768211456".initBigInt

    # shl
    doAssert one shl 63 == a63
    doAssert one shl 64 == a64
    doAssert one shl 65 == a65
    doAssert one shl 128 == a128
    doAssert x shl 0 == x
    doAssert x shl 1 == "380971427692029387694".initBigInt
    doAssert x shl 7 == "24382171372289880812416".initBigInt
    doAssert x shl 31 == "409064955661923745004158713856".initBigInt
    doAssert x shl 32 == "818129911323847490008317427712".initBigInt
    doAssert x shl 33 == "1636259822647694980016634855424".initBigInt
    doAssert x shl 53 == "1715742779792629411365922910161076224".initBigInt
    doAssert x shl 63 == "1756920606507652517238705060004942053376".initBigInt
    doAssert x shl 64 == "3513841213015305034477410120009884106752".initBigInt
    doAssert x shl 65 == "7027682426030610068954820240019768213504".initBigInt
    doAssert y shl 0 == y
    doAssert y shl 1 == "-380971427692029387694".initBigInt
    doAssert y shl 7 == "-24382171372289880812416".initBigInt
    doAssert y shl 31 == "-409064955661923745004158713856".initBigInt
    doAssert y shl 32 == "-818129911323847490008317427712".initBigInt
    doAssert y shl 33 == "-1636259822647694980016634855424".initBigInt
    doAssert y shl 53 == "-1715742779792629411365922910161076224".initBigInt
    doAssert y shl 63 == "-1756920606507652517238705060004942053376".initBigInt
    doAssert y shl 64 == "-3513841213015305034477410120009884106752".initBigInt
    doAssert y shl 65 == "-7027682426030610068954820240019768213504".initBigInt

    # shr
    doAssert a63 shr 63 == one
    doAssert a64 shr 64 == one
    doAssert a65 shr 65 == one
    doAssert a128 shr 128 == one
    doAssert -one shr 1 == -one
    doAssert -2.initBigInt shr 1 == -one
    doAssert x shr 0 == x
    doAssert x shr 1 == "95242856923007346923".initBigInt
    doAssert x shr 7 == "1488169639421989795".initBigInt
    doAssert x shr 31 == "88701822723".initBigInt
    doAssert x shr 32 == "44350911361".initBigInt
    doAssert x shr 33 == "22175455680".initBigInt
    doAssert x shr 53 == "21148".initBigInt
    doAssert x shr 63 == "20".initBigInt
    doAssert x shr 64 == "10".initBigInt
    doAssert x shr 65 == "5".initBigInt
    doAssert y shr 0 == y
    doAssert y shr 1 == "-95242856923007346924".initBigInt
    doAssert y shr 7 == "-1488169639421989796".initBigInt
    doAssert y shr 31 == "-88701822724".initBigInt
    doAssert y shr 32 == "-44350911362".initBigInt
    doAssert y shr 33 == "-22175455681".initBigInt
    doAssert y shr 53 == "-21149".initBigInt
    doAssert y shr 63 == "-21".initBigInt
    doAssert y shr 64 == "-11".initBigInt
    doAssert y shr 65 == "-6".initBigInt

  block: # bitwise operations
    let
      a = "123456789123456789123456789".initBigInt
      b = 567.initBigInt
      c = 1234.initBigInt
      d = "340282366920938463463374607431768211456".initBigInt
      e = 1.initBigInt
      f = 0.initBigInt

    doAssert (a and b) == 533.initBigInt
    doAssert (a and c) == 1040.initBigInt
    doAssert (b and c) == 18.initBigInt
    doAssert (a and d) == 0.initBigInt
    doAssert (b and d) == 0.initBigInt
    doAssert (a and e) == 1.initBigInt
    doAssert (d and e) == 0.initBigInt

    doAssert (a or b) == "123456789123456789123456823".initBigInt
    doAssert (a or c) == "123456789123456789123456983".initBigInt
    doAssert (b or c) == 1783.initBigInt
    doAssert (a or d) == "340282366921061920252498064220891668245".initBigInt
    doAssert (b or d) == "340282366920938463463374607431768212023".initBigInt
    doAssert (a or e) == a
    doAssert (d or e) == (d + e)

    doAssert (a xor b) == "123456789123456789123456290".initBigInt
    doAssert (a xor c) == "123456789123456789123455943".initBigInt
    doAssert (b xor c) == 1765.initBigInt
    doAssert (a xor d) == "340282366921061920252498064220891668245".initBigInt
    doAssert (b xor d) == "340282366920938463463374607431768212023".initBigInt
    doAssert (a xor e) == (a - e)
    doAssert (d xor e) == (d + e)
    doAssert (d xor d) == f
    doAssert (d xor f) == d

  block: # inc/dec
    var x: BigInt

    x = 42.initBigInt
    x.inc
    doAssert x == 43.initBigInt
    x.inc(int32.high)
    doAssert x == "2147483690".initBigInt
    x.inc(int32.low)
    doAssert x == 42.initBigInt
    x.inc(-42)
    doAssert x == 0.initBigInt

    x = 42.initBigInt
    x.dec
    doAssert x == 41.initBigInt
    x.dec(int32.high)
    doAssert x == "-2147483606".initBigInt
    x.dec(int32.low)
    doAssert x == 42.initBigInt
    x.dec(-42)
    doAssert x == 84.initBigInt

    # edge cases

    x = 1.initBigInt
    x.inc(int32.low)
    doAssert x == "-2147483647".initBigInt
    x = -1.initBigInt
    x.inc(2)
    doAssert x == 1.initBigInt
    x = -1.initBigInt
    x.inc(-2)
    doAssert x == -3.initBigInt

    x = 0.initBigInt
    x.dec(int32.low)
    doAssert x == "2147483648".initBigInt
    x = 1.initBigInt
    x.dec(-2)
    doAssert x == 3.initBigInt
    x = -1.initBigInt
    x.dec(-2)
    doAssert x == 1.initBigInt
    x = 12.initBigInt
    x.dec(42)
    doAssert x == -30.initBigInt

    when sizeof(int) == 8:
      # int has 64 bits
      x = 42.initBigInt
      x.inc(int32.high.int + 1)
      doAssert x == "2147483690".initBigInt
      x.inc(int64.high.int)
      doAssert x == "9223372039002259497".initBigInt
      x.inc(int32.low.int - 1)
      doAssert x == "9223372036854775848".initBigInt
      x.inc(int64.low.int)
      doAssert x == 40.initBigInt
      x.dec(int32.high.int + 1)
      doAssert x == "-2147483608".initBigInt
      x.dec(int64.high.int)
      doAssert x == "-9223372039002259415".initBigInt
      x.dec(int32.low.int - 1)
      doAssert x == "-9223372036854775766".initBigInt
      x.dec(int64.low.int)
      doAssert x == 42.initBigInt

  block: # string conversion
    for base in 2..36:
      # zero
      doAssert zero.toString(base) == "0"
      doAssert (-zero).toString(base) == "0" # no sign is produced for 0
      doAssert "0".initBigInt(base) == zero
      doAssert "-0".initBigInt(base) == zero
      doAssert "00000".initBigInt(base) == zero
      doAssert "-00000".initBigInt(base) == zero
      doAssert "00000000000000000000000000000000000".initBigInt(base) == zero
      doAssert "-00000000000000000000000000000000000".initBigInt(base) == zero

      # one
      doAssert one.toString(base) == "1"
      doAssert (-one).toString(base) == "-1"
      doAssert "1".initBigInt(base) == one
      doAssert "-1".initBigInt(base) == -one
      doAssert "00001".initBigInt(base) == one
      doAssert "-00001".initBigInt(base) == -one
      doAssert "00000000000000000000000000000000001".initBigInt(base) == one
      doAssert "-00000000000000000000000000000000001".initBigInt(base) == -one

    let a = initBigInt(uint64(uint32.high) + 1)
    doAssert a.toString(base = 2) == "100000000000000000000000000000000"
    doAssert a.toString(base = 3) == "102002022201221111211"
    doAssert a.toString(base = 4) == "10000000000000000"
    doAssert a.toString(base = 8) == "40000000000"
    doAssert a.toString(base = 10) == "4294967296"
    doAssert a.toString(base = 12) == "9ba461594"
    doAssert a.toString(base = 16) == "100000000"
    doAssert a.toString(base = 32) == "4000000"

    let b = initBigInt(0xfedcba9876543210'u64)
    doAssert "1111111011011100101110101001100001110110010101000011001000010000".initBigInt(base = 2) == b
    doAssert "11112100120110012201202221111221022102200".initBigInt(base = 3) == b
    doAssert "33323130232221201312111003020100".initBigInt(base = 4) == b
    doAssert "1773345651416625031020".initBigInt(base = 8) == b
    doAssert "18364758544493064720".initBigInt(base = 10) == b
    doAssert "833b81a74046633500".initBigInt(base = 12) == b
    doAssert "fedcba9876543210".initBigInt(base = 16) == b
    doAssert "ftn5qj1r58cgg".initBigInt(base = 32) == b

  block: # fastLog2
    let a = one shl 31
    let b = a shl 1
    let c = initBigInt(0xfedcba9876543210'u64)
    let d = initBigInt("ffffffffffffffffff", base = 16)

    # first numbers
    doAssert fastLog2(2.initBigInt) == 1
    doAssert fastLog2(3.initBigInt) == 1
    doAssert fastLog2(4.initBigInt) == 2
    doAssert fastLog2(5.initBigInt) == 2
    doAssert fastLog2(7.initBigInt) == 2
    doAssert fastLog2(8.initBigInt) == 3
    doAssert fastLog2(24.initBigInt) == 4
    doAssert fastLog2(32.initBigInt) == 5
    doAssert fastLog2(48.initBigInt) == 5

    # one limb
    doAssert fastLog2(a) == 31

    # two limbs and more
    doAssert fastLog2(b) == 32
    doAssert fastLog2(b+a) == 32
    doAssert fastLog2(c+b+a) == 63

    doAssert fastLog2(d) == 71
    doAssert fastLog2(d + one) == 72
    doAssert fastLog2(d - one) == 71
    doAssert fastLog2(-d) == 71
    doAssert fastLog2(-d - one) == 72
    doAssert fastLog2(-d + one) == 71

    # negative BigInts
    doAssert fastLog2(-2.initBigInt) == 1
    doAssert fastLog2(-3.initBigInt) == 1
    doAssert fastLog2(-4.initBigInt) == 2
    doAssert fastLog2(-5.initBigInt) == 2
    doAssert fastLog2(-7.initBigInt) == 2
    doAssert fastLog2(-8.initBigInt) == 3
    doAssert fastLog2(-24.initBigInt) == 4
    doAssert fastLog2(-32.initBigInt) == 5
    doAssert fastLog2(-48.initBigInt) == 5
    doAssert fastLog2(-a) == 31
    doAssert fastLog2(-b) == 32

    # edge cases
    doAssert fastLog2(one) == 0
    doAssert fastLog2(zero) == -1


  block: # pow
    let a = "14075287".initBigInt
    doAssert pow(a, 0) == one
    doAssert pow(a, 1) == a
    doAssert pow(a, 2) == a * a
    doAssert pow(a, 3) == a * a * a
    doAssert pow(a, 4) == a * a * a * a
    doAssert pow(a, 5) == a * a * a * a * a
    doAssert pow(a, 6) == a * a * a * a * a * a
    doAssert pow(a, 7) == a * a * a * a * a * a * a

    # special cases
    doAssert pow(zero, 0) == one
    doAssert pow(zero, 1) == zero

  block: # invmod
    # with prime modulus
    let a = "30292868".initBigInt
    let b = "48810860".initBigInt
    let p = "60449131".initBigInt # p is prime
    doAssert invmod(a, p) == "51713091".initBigInt
    doAssert invmod(-b, p) == "31975542".initBigInt
    # with composite modulus
    let c = "2472018".initBigInt
    let n = "3917515".initBigInt # 5 * 7 * 19 * 43 * 137
    let d = "1831482".initBigInt
    let e = "2502552".initBigInt
    let f = "2086033".initBigInt
    let h = "1414963".initBigInt
    doAssert invmod(c, n) == "2622632".initBigInt
    doAssert invmod(one, n) == one
    doAssert invmod(n-one, n) == n-one

    doAssert invmod( d, n) == h
    doAssert invmod(-d, n) == e
    doAssert invmod( f, n) == e
    doAssert invmod(-f, n) == h
    doAssert invmod( e, n) == f
    doAssert invmod(-e, n) == d
    doAssert invmod( h, n) == d
    doAssert invmod(-h, n) == f

    block:
      let
        a = "2147483647".initBigInt # M_31 mersenne prime
        b = "2147483649".initBigInt # a^-1 mod m
        m = "2305843009213693951".initBigInt # M_61 mersenne prime
      for x in [a - m - m, a - m, a, a + m, a + m + m]:
        doAssert invmod(x, m) == b
      for x in [b - m - m, b - m, b, b + m, b + m + m]:
        doAssert invmod(x, m) == a

    # exceptions
    doAssertRaises(DivByZeroDefect): discard invmod(zero, n)
    doAssertRaises(DivByZeroDefect): discard invmod(one, zero)
    doAssertRaises(ValueError): discard invmod(one, -7.initBigInt)
    doAssertRaises(ValueError): discard invmod(3.initBigInt, 18.initBigInt) # 3 is not invertible since gcd(3, 18) = 3 != 1
    for x in [-n - n, -n, n, n + n]:
      doAssertRaises(ValueError): discard invmod(x, n) # invmod(0, n)

    block: # https://rosettacode.org/wiki/Modular_inverse
      doAssert invmod(42.initBigInt, 2017.initBigInt) == 1969.initBigInt

  block: # powmod
    let a = "30292868".initBigInt
    let p = "60449131".initBigInt # p is prime
    let two = 2.initBigInt
    doAssert powmod(a, two, p) == "25760702".initBigInt
    # Fermat's little theorem: a^p ≡ a mod p
    doAssert powmod(a, p, p) == a
    # Euler's identity a^(p-1) \equiv 1 \bmod p
    doAssert powmod(a, p - one, p) == one
    # We can invert a using Euler's identity / Fermat's little theorem
    doAssert powmod(a, p - two, p) == "51713091".initBigInt
    # We can reduce the exponent modulo phi(p) = p - 1, since p is prime
    doAssert powmod(a, 2.initBigInt*p, p) == (a * a mod p)

    let p2 = 761.initBigInt
    var a2 = 1.initBigInt
    # Fermat's little theorem: a^p ≡ a mod p
    while a2 < p2:
      doAssert powmod(a2, p2, p2) == a2
      a2.inc

    block: # https://rosettacode.org/wiki/Modular_exponentiation
      let
        a = "2988348162058574136915891421498819466320163312926952423791023078876139".initBigInt
        b = "2351399303373464486466122544523690094744975233415544072992656881240319".initBigInt
        m = pow(10.initBigInt, 40)
      doAssert powmod(a, b, m) == "1527229998585248450016808958343740453059".initBigInt

    block: # Composite modulus
      let a = "2472018".initBigInt
      let n = "3917515".initBigInt # 5 * 7 * 19 * 43 * 137
      let euler_phi = "2467584".initBigInt
      doAssert powmod(a, 52.initBigInt, n) == "2305846".initBigInt
      doAssert powmod(a, euler_phi, n) == one
      # Edge cases
      doAssert powmod(a, one, n) == a
      doAssert powmod(a, zero, n) == one
      doAssert powmod(zero, zero, n) == one
      doAssert powmod(zero, one, n) == zero

    block: # powmod with negative base
      let a = "1986599".initBigInt
      let p = "10230581".initBigInt
      doAssert powmod(-a, 2.initBigInt, p) == "6199079".initBigInt

    block: # powmod with negative exponent
      let a = "1912".initBigInt
      let p = "5297".initBigInt
      doAssert powmod(a, -1.initBigInt, p) == "1460".initBigInt
      doAssert powmod(a, one-p, p) == one

  block: # div/mod
    doAssertRaises(DivByZeroDefect): discard one div zero
    doAssertRaises(DivByZeroDefect): discard one mod zero
    doAssertRaises(DivByZeroDefect): discard divmod(one, zero)

  block: # gcd
    let a = "866506".initBigInt
    let b = "140640".initBigInt
    let two = 2.initBigInt
    doAssert gcd(a, b) == two
    # gcd(a, b) = gcd(b, a)
    doAssert gcd(b, a) == two
    # gcd(a, -b) = gcd(a, |b|)
    doAssert gcd(-a, b) == two
    doAssert gcd(a, -b) == two
    doAssert gcd(-a, -b) == two

    block: # properties of gcd
      let a = "668403".initBigInt
      let b = "753160".initBigInt
      let c = "249115".initBigInt
      doAssert gcd(a, b) == gcd(b, a)
      doAssert gcd(a, zero) == a
      doAssert gcd(a, a) == a
      doAssert gcd(c * a, c * b) == c * gcd(a,b)
      doAssert gcd(a, gcd(b, c)) == gcd(gcd(a, b), c)
      doAssert gcd(a, b) == gcd(b, a mod b)

  block: # abs
    doAssert abs(zero) == zero
    doAssert abs(-zero) == zero
    doAssert abs(one) == one
    doAssert abs(-one) == one

  block: # toInt
    let
      a = initBigInt(7)
      b = initBigInt(-7)
    doAssert toInt[int8](a) == some(7'i8)
    doAssert toInt[int8](b) == some(-7'i8)
    doAssert toInt[uint8](a) == some(7'u8)
    doAssert toInt[uint8](b) == none(uint8)
    doAssert toInt[int16](a) == some(7'i16)
    doAssert toInt[int16](b) == some(-7'i16)
    doAssert toInt[uint16](a) == some(7'u16)
    doAssert toInt[uint16](b) == none(uint16)

    block: # int32
      let
        i32h = int32.high
        i32l = int32.low
        c = initBigInt(i32h)
        d = initBigInt(i32h - 1)
        e = initBigInt(int64(i32h) + 1)
        f = initBigInt(i32l)
        g = initBigInt(i32l + 1)
        h = initBigInt(int64(i32l) - 1)
      doAssert toInt[int8](c) == none(int8)
      doAssert toInt[int16](c) == none(int16)
      doAssert toInt[int32](c) == some(i32h)
      doAssert toInt[int](c) == some(i32h.int)
      doAssert toInt[int8](d) == none(int8)
      doAssert toInt[int16](d) == none(int16)
      doAssert toInt[int32](d) == some(i32h - 1)
      doAssert toInt[int](d) == some(i32h.int - 1)
      doAssert toInt[int8](e) == none(int8)
      doAssert toInt[int16](e) == none(int16)
      doAssert toInt[int32](e) == none(int32)
      doAssert toInt[int64](e) == some(i32h.int64 + 1)
      doAssert toInt[int8](f) == none(int8)
      doAssert toInt[int16](f) == none(int16)
      doAssert toInt[int32](f) == some(i32l)
      doAssert toInt[int](f) == some(i32l.int)
      doAssert toInt[int8](g) == none(int8)
      doAssert toInt[int16](g) == none(int16)
      doAssert toInt[int32](g) == some(i32l + 1)
      doAssert toInt[int](g) == some(i32l.int + 1)
      doAssert toInt[int8](h) == none(int8)
      doAssert toInt[int16](h) == none(int16)
      doAssert toInt[int32](h) == none(int32)
      doAssert toInt[int64](h) == some(i32l.int64 - 1)

    block: # uint32
      let
        u32h = uint32.high
        a = initBigInt(u32h)
        b = initBigInt(u32h - 1)
        c = initBigInt(uint64(u32h) + 1)
      doAssert toInt[uint8](a) == none(uint8)
      doAssert toInt[uint16](a) == none(uint16)
      doAssert toInt[uint32](a) == some(u32h)
      doAssert toInt[uint](a) == some(u32h.uint)
      doAssert toInt[uint8](b) == none(uint8)
      doAssert toInt[uint16](b) == none(uint16)
      doAssert toInt[uint32](b) == some(u32h - 1)
      doAssert toInt[uint](b) == some(u32h.uint - 1)
      doAssert toInt[uint8](c) == none(uint8)
      doAssert toInt[uint16](c) == none(uint16)
      doAssert toInt[uint32](c) == none(uint32)
      doAssert toInt[uint64](c) == some(u32h.uint64 + 1)

    block: # int64
      let
        i64h = int64.high
        i64l = int64.low
        i = initBigInt(i64h)
        j = initBigInt(i64h - 1)
        k = initBigInt(uint64(int64.high) + 1)
        l = initBigInt(i64l)
        m = initBigInt(i64l + 1)
        n = initBigInt(int64.low) - one
      doAssert toInt[int8](i) == none(int8)
      doAssert toInt[int16](i) == none(int16)
      doAssert toInt[int32](i) == none(int32)
      doAssert toInt[int64](i) == some(i64h)
      doAssert toInt[int8](j) == none(int8)
      doAssert toInt[int16](j) == none(int16)
      doAssert toInt[int32](j) == none(int32)
      doAssert toInt[int64](j) == some(i64h - 1)
      doAssert toInt[int8](k) == none(int8)
      doAssert toInt[int16](k) == none(int16)
      doAssert toInt[int32](k) == none(int32)
      doAssert toInt[int64](k) == none(int64)
      doAssert toInt[int8](l) == none(int8)
      doAssert toInt[int16](l) == none(int16)
      doAssert toInt[int32](l) == none(int32)
      doAssert toInt[int64](l) == some(i64l)
      doAssert toInt[int8](m) == none(int8)
      doAssert toInt[int16](m) == none(int16)
      doAssert toInt[int32](m) == none(int32)
      doAssert toInt[int64](m) == some(i64l + 1)
      doAssert toInt[int8](n) == none(int8)
      doAssert toInt[int16](n) == none(int16)
      doAssert toInt[int32](n) == none(int32)
      doAssert toInt[int64](n) == none(int64)

    block: # uint64
      let
        u64h = uint64.high
        a = initBigInt(u64h)
        b = initBigInt(u64h - 1)
        c = initBigInt(uint64.high) + one
      doAssert toInt[uint8](a) == none(uint8)
      doAssert toInt[uint16](a) == none(uint16)
      doAssert toInt[uint32](a) == none(uint32)
      doAssert toInt[uint64](a) == some(u64h)
      doAssert toInt[uint8](b) == none(uint8)
      doAssert toInt[uint16](b) == none(uint16)
      doAssert toInt[uint32](b) == none(uint32)
      doAssert toInt[uint64](b) == some(u64h - 1)
      doAssert toInt[uint8](c) == none(uint8)
      doAssert toInt[uint16](c) == none(uint16)
      doAssert toInt[uint32](c) == none(uint32)
      doAssert toInt[uint64](c) == none(uint64)

  block: # pred/succ
    let a = initBigInt(7)
    doAssert pred(a) == initBigInt(6)
    doAssert succ(a) == initBigInt(8)
    doAssert pred(a, 3) == initBigInt(4)
    doAssert succ(a, 3) == initBigInt(10)


static: main()
main()
