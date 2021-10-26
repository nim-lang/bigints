# Pure BigInts for Nim

![test](https://github.com/def-/nim-bigints/workflows/test/badge.svg)

This library provides a pure implementation for arbitrary precision integers in [Nim](https://nim-lang.org/).

It can be installed through nimble with:

```
nimble install https://github.com/nim-lang/bigints
```

`bigints` provides a `BigInt` type and related operations with standard Nim syntax:

- creation of `BigInt` from all standard integer types (`initBigInt`)
- comparisons (`<`, `<=`, `==`)
- addition, negation and subtraction (`+`, `-`, `+=` `-=`)
- multiplication (`*`, `*=`)
- bit shifts (`shr`, `shl`)
- bitwise `and`, `or` and `xor` (limited to non-negative numbers)
- integer division and modulo operation (`div`, `mod`)
- conversion of `BigInt` from/to strings supporting bases from 2 to 36 (`initBigInt`, `$`)
- iteration utilities (`inc`, `dec`, `countdown`, `countup`, `..`, `..<`)



## Current limitations and possible enhancements

* not expected to work on 32 bit
* bitwise `not` operation is not implemented
* arithmetical operations such as addition, multiplication and division are not optimized for performance (e.g. [karatsuba multiplication](https://en.wikipedia.org/wiki/Karatsuba_algorithm) is not implemented)



## Documentation

The documentation is available at: https://nimdocs.com/nim-lang/bigints/bigints.html
