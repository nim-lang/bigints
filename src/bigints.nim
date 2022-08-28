## Arbitrary precision integers.

import std/[algorithm, math, options]

include
  bigints/[initBigInt, comparisonOperators, arithmeticOperators, shiftingOperators, division, stringConversion]

when (NimMajor, NimMinor) >= (1, 5):
  include bigints/private/literals

include bigints/[increments, arithmetic]
