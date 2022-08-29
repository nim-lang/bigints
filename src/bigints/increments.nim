# inc, dec, succ, pred, `..`, `..<`, countup, and countdown
include division

func inc*(a: var BigInt, b: int = 1) =
  ## Increase the value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15.initBigInt
    inc a
    assert a == 16.initBigInt
    inc(a, 7)
    assert a == 23.initBigInt

  if b in int32.low..int32.high:
    var c = a
    additionInt(a, c, b.int32)
  else:
    a += initBigInt(b)

func dec*(a: var BigInt, b: int = 1) =
  ## Decrease the value of a `BigInt` by the specified amount (default: 1).
  runnableExamples:
    var a = 15.initBigInt
    dec a
    assert a == 14.initBigInt
    dec(a, 5)
    assert a == 9.initBigInt

  if b in int32.low..int32.high:
    var c = a
    subtractionInt(a, c, b.int32)
  else:
    a -= initBigInt(b)

func succ*(a: BigInt, b: int = 1): BigInt =
  ## Returns the `b`-th successor of a `BigInt`.
  result = a
  inc(result, b)

func pred*(a: BigInt, b: int = 1): BigInt =
  ## Returns the `b`-th predecessor of a `BigInt`.
  result = a
  dec(result, b)


iterator countup*(a, b: BigInt, step: int32 = 1): BigInt =
  ## Counts from `a` up to `b` (inclusive) with the given step count.
  var res = a
  while res <= b:
    yield res
    inc(res, step)

iterator countdown*(a, b: BigInt, step: int32 = 1): BigInt =
  ## Counts from `a` down to `b` (inclusive) with the given step count.
  var res = a
  while res >= b:
    yield res
    dec(res, step)

iterator `..`*(a, b: BigInt): BigInt =
  ## Counts from `a` up to `b` (inclusive).
  var res = a
  while res <= b:
    yield res
    inc res

iterator `..<`*(a, b: BigInt): BigInt =
  ## Counts from `a` up to `b` (exclusive).
  var res = a
  while res < b:
    yield res
    inc res

