import std/options
import bigints

proc main() =
  block: # range of BigInt (https://github.com/nim-lang/bigints/issues/1)
    let two = 2.initBigInt
    let n = "123".initBigInt
    var result = 1.initBigInt
    for i in two .. n:
      result *= i
    doAssert result == initBigInt("12146304367025329675766243241881295855454217088483382315328918161829235892362167668831156960612640202170735835221294047782591091570411651472186029519906261646730733907419814952960000000000000000000000000000")

  block: # multiple multiplications (https://github.com/nim-lang/bigints/issues/3)
    let nums = [
      "68855123440532288245010625",
      "201850901852714536181760000",
      "435980903974422631450250625",
      "824199001261152424427520000",
      "11527258048987096618327125",
      "18960243520191483654144000",
    ]

    var total = 1.initBigInt

    for e in items(nums):
      let bigInt = e.initBigInt
      total *= bigInt

    doAssert total == initBigInt("1091531901753858845417645933677882391421406095571139520376889755608568225321090455009925801178698945969179844505331560015898829746339840000000000000000000000")

  block: # "negative BigInt (https://github.com/nim-lang/bigints/issues/4)
    let x = -initBigInt(1)
    doAssert x == initBigInt(-1)

  block: # off by one in division (https://github.com/nim-lang/bigints/issues/5)
    block:
      var x = initBigInt("815915283247897734345611269596115894272000000000")
      var y = initBigInt("5919012181389927685417441689600000000")
      doAssert x div y == initBigInt("137846528820")

    block:
      var x = initBigInt("815915283247897734345611269596115894272000000000")
      var y = initBigInt("20000000000")
      doAssert x div y == initBigInt("40795764162394886717280563479805794713")

  block: # negative zero flags (https://github.com/nim-lang/bigints/issues/16)
    let
      a = initBigInt("828478292990482")
      b = initBigInt(9283)
      c = initBigInt("-828478292990482")
      d = initBigInt(-9283)
      e = initBigInt(0)
    doAssert b + d == e
    doAssert a + c == e

    doAssert d + b == e
    doAssert c + a == e

    doAssert b - b == e
    doAssert d - d == e

    doAssert d * e == e
    doAssert b * e == e
    doAssert e div d == e

  block: # validate digits in string parsing (https://github.com/nim-lang/bigints/issues/24)
    doAssert initBigInt("1", 2) == initBigInt(1)
    doAssert initBigInt("z", 36) == initBigInt(35)
    doAssertRaises(ValueError):
      discard initBigInt("2", 2)
    doAssertRaises(ValueError):
      discard initBigInt("z", 35)

  block: # empty limbs when uninitialized (https://github.com/nim-lang/bigints/issues/26)
    var a: BigInt
    let b = 12.initBigInt

    doAssert a * b == 0.initBigInt

  block: # IndexError with a = a + b (https://github.com/nim-lang/bigints/issues/27)
    var
      a = 0.initBigInt
      b = "359097073186387306".initBigInt

    a = a + b  # Error: unhandled exception: index out of bounds, the container is empty [IndexError]

  block: # toInt[int64] produces wrong results in certain cases (https://github.com/nim-lang/bigints/issues/99)
    doAssert toInt[int64](-initBigInt(0xFFFFFFFF_00000000'u64)) == none(int64)

static: main()
main()
