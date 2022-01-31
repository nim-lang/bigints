# Translation of https://rosettacode.org/wiki/Hamming_numbers#Another_implementation_of_same_approach
import bigints

const
  two = initBigInt(2)
  three = initBigInt(3)
  five = initBigInt(5)

proc hamming(limit: int): BigInt =
  var
    h = newSeq[BigInt](limit)
    x2 = two
    x3 = three
    x5 = five
    i, j, k = 0
  for i in 0..h.high: h[i] = initBigInt(1)

  for n in 1 ..< limit:
    h[n] = min([x2, x3, x5])
    if x2 == h[n]:
      inc i
      x2 = h[i] * two
    if x3 == h[n]:
      inc j
      x3 = h[j] * three
    if x5 == h[n]:
      inc k
      x5 = h[k] * five

  result = h[h.high]

for i in 1 .. 20:
  stdout.write hamming(i), " "

echo hamming(1691)
echo hamming(1_000_000)
