# Pure BigInts for Nim

[![test](https://github.com/nim-lang/bigints/actions/workflows/test.yaml/badge.svg)](https://github.com/nim-lang/bigints/actions/workflows/test.yaml)

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
- bitwise `not`, `and`, `or` and `xor` (behave as if negative numbers were represented in 2's complement)
- integer division and modulo operation (`div`, `mod`)
- conversion of `BigInt` from/to strings supporting bases from 2 to 36 (`initBigInt`, `$`)
- iteration utilities (`inc`, `dec`, `countdown`, `countup`, `..`, `..<`)



## Current limitations and possible enhancements

* arithmetic operations such as addition, multiplication and division are not optimized for performance (e.g. [Karatsuba multiplication](https://en.wikipedia.org/wiki/Karatsuba_algorithm) is not implemented)



## Documentation

The documentation is available at https://nim-lang.github.io/bigints.
