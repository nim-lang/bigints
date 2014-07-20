# Solution for http://rosettacode.org/wiki/Arbitrary-precision_integers_(included)

import bigints

var x = 5.pow 4.pow 3.pow 2
var s = $x

echo s[0..19]
echo s[s.high - 19 .. s.high]
echo s.len
