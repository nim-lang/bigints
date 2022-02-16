# This program prints as much pi digits as the user indicates
# with the first command line argument
# This program is an extension of the solution for https://rosettacode.org/wiki/Pi
# translated from former website http://benchmarksgame.alioth.debian.org

import std/[os, strutils, options]
import bigints

const
  zero = 0.initBigInt
  one = 1.initBigInt
  two = 2.initBigInt
  ten = 10.initBigInt
let
  mask = (one shl 32) - one

var
  tmp1, tmp2, tmp3, acc, k = zero
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

  result = get(toInt[int32](tmp1 and mask))

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

proc findPiDigit(): int32 =
  result = -1
  while result < 0:
    nextTerm()
    result = extractDigit()

var i = 0
if paramCount() == 0:
  # prints an infinite amount of pi digits
  while true:
    var d: int32 = findPiDigit()
    stdout.write chr(ord('0') + d)
    inc i
    if i == 40:
      echo ""
      i = 0
    eliminateDigit(d)

let n = parseInt(paramStr(1))

if n <= 0:
  quit("The number you entered is negative. Please specify a strictly positive number")

while i < n:
  var d: int32 = findPiDigit()
  stdout.write(chr(ord('0') + d))
  inc(i)
  if i mod 40 == 0:
    echo "\t:", i
  eliminateDigit(d)
