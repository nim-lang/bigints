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

  block: # multiplication
    # factors with 4 limbs
    let a = "1780983279228119273110576463639172624".initBigInt
    let b = "1843917749452418885995463656480858321".initBigInt
    echo a * b
    doAssert a * b == "3283986680046702618742503890385314117448805445290098330749803441805804304".initBigInt

    # factors with 17 limbs
  let c = "15456863493948186026689401110531937466657435954521677287549013772194751214595085262021623597960658907994197330891108031896474775438991400654520526954653285".initBigInt
  let d = "20867311096234429137120990056519061484140179793024844459539745043528236531589522382271230666075358518275274769618792229717222657110424037636116966396665200".initBigInt
  doAssert c * d == "322543179100245850295291096700090285623536165554432133161470913224665233565153206743023505404409261647296075477738317301701554637184306640109864382144645081119052516436652162825894456855767719709860985552674755702938369565636714472650667032224717209489767579823588160939485446085000195032327964706246225182000".initBigInt

  # factors with 65 limbs
  let e = initBigInt("1f3b839241b0aacc183858dc7a75a773e7bad642a9f426ef499d91e09c9f99a88ec9a14d5ee51175faeaa10d2fb06f3ee37d2f50fe755c2c963aeb539cd55c0e14f5a23f04c64839c22bd4108034b7afc95e01a1c2fe605d8b1930926e886a8f3d7fc09acd54d388cb5d4b3a3fb4eaf6781173ab3a0cd8ad3119c37dd2cf05544235d7b85b2c96d2ed29e1a685820c4afdd824bd8878f1b6a3f52a57eb886efaa737af47161c89f298d908aa950979b8c2615d4e03b47ee87a5381ca39d9ec4788d7abd07b174913b962c02cdd5f8319722a3345eb38d3ebdd51dec66a58e89902151539298c41446758bac66923c910fd7a2d12d0d5c8bb688970b8a77e7d5fc", base = 16)
  let f = initBigInt("116be4e445ea68066fca5652e472eb1c1a5fb850311126a8a91fd6f1199f92a9d6602a81bb5e500d163b01df7eec15e41109c62f6c83425027272823d9888a51c93422d47ba4e1cecb94d6fa02eb27df537038b2ac7c9c264634b8febc452c5c9043ddc7d2eddd04f1f743d85cfefd0864441bb9cbf46308138d037b2057980c8b6d215e6bd2c0a73d64c176b7b59452a2c7968a121e5d46c859d85678acd0d4927509418fd351331791fdb7ad041ee2e7d5975867f1812d1e17a41f5a7c0735ebe224294f5ca9d607e95a8722adf58f676b23da1563ac62a52352c10efd0bf5cc8b5eb9ddd7fd1c22bc307d5edf86474f66302fd7cd288a9bc251d3ba45a851b", base = 16)
  doAssert e * f == initBigInt("2201d898f354480704067f8513e7b8b365db60c9132d96e54b8546c05c59a08f50b8d8488841d9e893b3c6de34e22b70f2f6c9bc682700c060b60b6e614c9cc39a2c9a9c13ccc412a512c8126f60e1572d20281855e63d019be43a34a929c20818d05527e75f9edf4c5c9a096c4412f879ca14dd3f8bc48aafea6ce17223adefc1e55ca8216ed3d6d351f08dc38a5e6fed7cb3abd1844bfaed632a1571d0017f1285b2e7762c8c3ad0adc781f47df619f462415b8b4e3496fea3d1b1f4443184a5f5fdc155af2f62d861c9ab321a5083c07b4fdfc384aaa6c4a09559e1d7383b5a3fd9f6c9dfe2079c13bfcf307f98de6e16e474b55e94dcf9dbaf3e90ba38f37ddc69c318ed680a0db8a5d5257a1214c765b267f3df8352ad5b4ee9e9c27ca7085ee5687e6afc8108b683c622613c003c068b60bed656d2dc6a32b1f7b079194108301da8d8049f5b64e88da091803bf1582a45fd24f242f2d9b9d8090c4d088ea31faa3e997d20688481b8f1847524f28153e0ba5c3017338cf470c906d8b27352082741dcfb81ec81a3268569424f791c9a82777d66f2b6a52e0653843057da444b55ddb5f517f1676daafa3413ee3dc6dc0a8edc7cfcbd4b6dd5653957baa93e35fad6908addc018706b0acf64cd5cfe3ee462b57e2cc58f641a883a693505fab131a8f51f22cc34ff694af1e4ca0b4d8469067a76b378783b190c2377d94", base = 16)

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

    doAssertRaises(DivByZeroDefect): discard invmod(zero, n)
    doAssertRaises(DivByZeroDefect): discard invmod(one, zero)
    doAssertRaises(ValueError): discard invmod(one, -7.initBigInt)
    doAssertRaises(ValueError): discard invmod(3.initBigInt, 18.initBigInt) # 3 is not invertible since gcd(3, 18) = 3 != 1

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


static: main()
main()
