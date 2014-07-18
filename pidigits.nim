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

proc extractDigit(): int64 =
  if num > acc:
    return -1

  tmp1 = num shl 1
  tmp1 += num
  tmp1 += acc
  tmp2 = tmp1 mod den
  tmp1 = tmp1 div den
  tmp2 += num

  if tmp2 >= den:
    return -1

  result = int64(tmp1.limbs[0])

proc eliminateDigit(d: BigInt) =
  acc -= den * d
  acc *= ten
  num *= ten

proc nextTerm(k: BigInt) =
  let k2 = k * two + one
  tmp1 = num shl 1
  acc += tmp1
  acc *= k2
  den *= k2
  num *= k

let n = parseInt(paramStr(1))
var i = 0

while i < n:
  var d: int64 = -1
  while d < 0:
    k += one
    nextTerm(k)
    d = extractDigit()

  stdout.write(chr(ord('0') + d))
  inc(i)
  if i mod 10 == 0:
    echo "\t:", i
  if i >= n:
    break
  dd.limbs[0] = uint32(d)
  eliminateDigit(dd)
