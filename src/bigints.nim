## Arbitrary precision integers.

include bigints/arithmetic
when (NimMajor, NimMinor) >= (1, 5):
  include bigints/private/literals
