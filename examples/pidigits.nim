# Translation of http://benchmarksgame.alioth.debian.org/u32/program.php?test=pidigits&lang=go&id=4

import std/[os, strutils]
import bigints

const
  zero = 0.initBigInt
  one = 1.initBigInt
  two = 2.initBigInt
  ten = 10.initBigInt
let
  mask = (one shl 32) - one

var
  tmp1, tmp2, tmp3, acc, k, dd = zero
  den, num, k2 = one

proc extractDigit(): int32 =
  if num > acc:
    return -1

  tmp3 = num shl 1
  tmp3 += num
  tmp3 += acc
  tmp2 = tmp3 mod den
  tmp1 = tmp3 div den
  tmp2 += num

  if tmp2 >= den:
    return -1

  result = cast[int32](tmp1 and mask)

proc eliminateDigit(d: int32) =
  acc -= den * d.initBigInt
  acc *= ten
  num *= ten

proc nextTerm() =
  k += one
  k2 += two
  tmp1 = num shl 1
  acc += tmp1
  acc *= k2
  den *= k2
  num *= k

let n = parseInt(paramStr(1))
var i = 0

while i < n:
  var d: int32 = -1
  while d < 0:
    nextTerm()
    d = extractDigit()

  stdout.write(chr(ord('0') + d))
  inc(i)
  if i mod 10 == 0:
    echo "\t:", i
  if i >= n:
    break
  eliminateDigit(d)
