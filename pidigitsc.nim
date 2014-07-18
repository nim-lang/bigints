import os, strutils, unsigned, bigints

var
  tmp1, tmp2, acc, k, dd = initBigInt(0)
  den, num = initBigInt(1)

const
  one = initBigInt(1)
  two = initBigInt(2)
  three = initBigInt(3)
  four = initBigInt(4)
  ten = initBigInt(10)

proc extractDigit(nth: BigInt): uint32 =
  tmp1 = num * nth
  tmp2 = tmp1 + acc
  tmp1 = tmp2 div den
  tmp1.limbs[0]

proc eliminateDigit(d: BigInt) =
  acc -= den * d
  acc *= ten
  num *= ten

proc nextTerm(k: BigInt) =
  let k2 = k * two + one
  acc += num * two
  acc *= k2
  den *= k2
  num *= k

let n = parseInt(paramStr(1))
var i = 0

while i < n:
  k += initBigInt(1)
  nextTerm(k)

  if num > acc:
    continue

  let d = extractDigit(three)
  if d != extractDigit(four):
    continue

  stdout.write(chr(ord('0') + int64(d)))
  inc(i)
  if i mod 10 == 0:
    echo "\t:", i
  dd.limbs[0] = uint32(d)
  eliminateDigit(dd)
