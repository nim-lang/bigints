# Solution for http://rosettacode.org/wiki/Arbitrary-precision_integers_(included)

import bigints
import std/math

const five = 5.initBigInt

var x = five ^ (4 ^ (3 ^ 2)).int32
var s = $x

echo s[0..19]
echo s[s.high - 19 .. s.high]
echo s.len
