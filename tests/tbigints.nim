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

  block: # div/mod
    doAssertRaises(DivByZeroDefect): discard one div zero
    doAssertRaises(DivByZeroDefect): discard one mod zero
    doAssertRaises(DivByZeroDefect): discard divmod(one, zero)

  block: # toSignedInt
    let
      a = initBigInt(7)
      b = initBigInt(-7)
    doAssert toSignedInt[int8](a) == some(7'i8)
    doAssert toSignedInt[int8](b) == some(-7'i8)

    let
      i32h = int32.high
      i32l = int32.low
      c = initBigInt(i32h)
      d = initBigInt(i32h - 1)
      e = initBigInt(int64(i32h) + 1)
      f = initBigInt(i32l)
      g = initBigInt(i32l + 1)
      h = initBigInt(int64(i32l) - 1)
    doAssert toSignedInt[int8](c) == none(int8)
    doAssert toSignedInt[int32](c) == some(i32h)
    doAssert toSignedInt[int](c) == some(i32h.int)
    doAssert toSignedInt[int8](d) == none(int8)
    doAssert toSignedInt[int32](d) == some(i32h - 1)
    doAssert toSignedInt[int](d) == some(i32h.int - 1)
    doAssert toSignedInt[int8](e) == none(int8)
    doAssert toSignedInt[int32](e) == none(int32)
    doAssert toSignedInt[int64](e) == some(i32h.int64 + 1)
    doAssert toSignedInt[int8](f) == none(int8)
    doAssert toSignedInt[int32](f) == some(i32l)
    doAssert toSignedInt[int](f) == some(i32l.int)
    doAssert toSignedInt[int8](g) == none(int8)
    doAssert toSignedInt[int32](g) == some(i32l + 1)
    doAssert toSignedInt[int](g) == some(i32l.int + 1)
    doAssert toSignedInt[int8](h) == none(int8)
    doAssert toSignedInt[int32](h) == none(int32)
    doAssert toSignedInt[int64](h) == some(i32l.int64 - 1)

    let
      i64h = int64.high
      i64l = int64.low
      i = initBigInt(i64h)
      j = initBigInt(i64h - 1)
      k = initBigInt(uint64(int64.high) + 1)
      l = initBigInt(i64l)
      m = initBigInt(i64l + 1)
      n = initBigInt("-9223372036854775809") # int64.low - 1
    doAssert toSignedInt[int8](i) == none(int8)
    doAssert toSignedInt[int32](i) == none(int32)
    doAssert toSignedInt[int64](i) == some(i64h)
    doAssert toSignedInt[int8](j) == none(int8)
    doAssert toSignedInt[int32](j) == none(int32)
    doAssert toSignedInt[int64](j) == some(i64h - 1)
    doAssert toSignedInt[int8](k) == none(int8)
    doAssert toSignedInt[int32](k) == none(int32)
    doAssert toSignedInt[int64](k) == none(int64)
    doAssert toSignedInt[int8](l) == none(int8)
    doAssert toSignedInt[int32](l) == none(int32)
    doAssert toSignedInt[int64](l) == some(i64l)
    doAssert toSignedInt[int8](m) == none(int8)
    doAssert toSignedInt[int32](m) == none(int32)
    doAssert toSignedInt[int64](m) == some(i64l + 1)
    doAssert toSignedInt[int8](n) == none(int8)
    doAssert toSignedInt[int32](n) == none(int32)
    doAssert toSignedInt[int64](n) == none(int64)

  block: # pred/succ
    let a = initBigInt(7)
    doAssert pred(a) == initBigInt(6)
    doAssert succ(a) == initBigInt(8)
    doAssert pred(a, 3) == initBigInt(4)
    doAssert succ(a, 3) == initBigInt(10)

when (not defined(js)) or (NimMajor, NimMinor) >= (1, 6):
  static: main()
when not defined(js): # XXX: pending https://github.com/nim-lang/bigints/issues/59
  main()
