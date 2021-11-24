# This is an include file, do not import it directly.
# It is needed as a workaround for Nim's parser for versions <= 1.4.

proc `'bi`*(s: string): BigInt =
  ## Create a `BigInt` from a literal, using the suffix `'bi`.
  runnableExamples:
    let
      a = 123'bi
      b = 0xFF'bi
      c = 0b1011'bi
    assert $a == "123"
    assert $b == "255"
    assert $c == "11"
  case s[0..min(s.high, 1)]
  of "0x", "0X": initBigInt(s[2..s.high], base = 16)
  of "0b", "0B": initBigInt(s[2..s.high], base = 2)
  else: initBigInt(s)
