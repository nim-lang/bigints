import bigints

#var x = initBigInt(5) ^ (initBigInt(4) ^ (initBigInt(3) ^ initBigInt(2)))
var x = 5.pow 4.pow 3.pow 2
var s = $x

echo s[0..19]
echo s[s.high - 19 .. s.high]
echo s.len
