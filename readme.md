# Pure BigInts for Nim

![test](https://github.com/def-/nim-bigints/workflows/test/badge.svg)

The following api documentation is generated with [mddoc](https://github.com/treeform/mddoc). To regenerate install `mddoc` with nimble and run

```
mddoc .\src\bigints.nim
```

# API: bigints

```nim
import bigints
```

## **type** Flags


```nim
Flags = enum
 Negative
```

## **type** BigInt


```nim
BigInt = tuple[limbs: seq[uint32], flags: set[Flags]]
```

## **proc** initBigInt


```nim
proc initBigInt(vals: seq[uint32]; flags: set[Flags] = {}): BigInt
```

## **proc** initBigInt


```nim
proc initBigInt[T: int8 | int16 | int32](val: T): BigInt
```

## **proc** initBigInt


```nim
proc initBigInt[T: uint8 | uint16 | uint32](val: T): BigInt
```

## **proc** initBigInt


```nim
proc initBigInt(val: int64): BigInt
```

## **proc** initBigInt


```nim
proc initBigInt(val: uint64): BigInt
```

## **template** initBigInt


```nim
template initBigInt(val: int): BigInt
```

## **template** initBigInt


```nim
template initBigInt(val: uint): BigInt
```

## **proc** initBigInt


```nim
proc initBigInt(val: BigInt): BigInt
```

## **proc** cmp


```nim
proc cmp(a, b: BigInt): int64
```

## **proc** cmp


```nim
proc cmp(a: int32; b: BigInt): int64
```

## **proc** cmp


```nim
proc cmp(a: BigInt; b: int32): int64
```

## **proc** `&lt;`


```nim
proc `<`(a, b: BigInt): bool
```

## **proc** `&lt;`


```nim
proc `<`(a: BigInt; b: int32): bool
```

## **proc** `&lt;`


```nim
proc `<`(a: int32; b: BigInt): bool
```

## **proc** `&lt;=`


```nim
proc `<=`(a, b: BigInt): bool
```

## **proc** `&lt;=`


```nim
proc `<=`(a: BigInt; b: int32): bool
```

## **proc** `&lt;=`


```nim
proc `<=`(a: int32; b: BigInt): bool
```

## **proc** `==`


```nim
proc `==`(a, b: BigInt): bool
```

## **proc** `==`


```nim
proc `==`(a: BigInt; b: int32): bool
```

## **proc** `==`


```nim
proc `==`(a: int32; b: BigInt): bool
```

## **proc** `-`


```nim
proc `-`(a: BigInt): BigInt
```

## **proc** `+`


```nim
proc `+`(a: BigInt; b: int32): BigInt
```

## **proc** `+`


```nim
proc `+`(a, b: BigInt): BigInt
```

## **template** `+=`


```nim
template `+=`(a: var BigInt; b: BigInt)
```

## **template** `+=`


```nim
template `+=`(a: var BigInt; b: int32)
```

## **template** optAddInt


```nim
template optAddInt{
 x = y + z
}(x, y: BigInt; z: int32)
```

## **template** optAdd


```nim
template optAdd{
 x = y + z
}(x, y, z: BigInt)
```

## **proc** `-`


```nim
proc `-`(a: BigInt; b: int32): BigInt
```

## **template** `-=`


```nim
template `-=`(a: var BigInt; b: int32)
```

## **proc** `-`


```nim
proc `-`(a, b: BigInt): BigInt
```

## **template** `-=`


```nim
template `-=`(a: var BigInt; b: BigInt)
```

## **template** optSub


```nim
template optSub{
 x = y - z
}(x, y, z: BigInt)
```

## **proc** `*`


```nim
proc `*`(a: BigInt; b: int32): BigInt
```

## **template** `*=`


```nim
template `*=`(a: var BigInt; b: int32)
```

## **proc** `*`


```nim
proc `*`(a, b: BigInt): BigInt
```

## **template** `*=`


```nim
template `*=`(a: var BigInt; b: BigInt)
```

## **template** optMulInt


```nim
template optMulInt{
 x = `*`(y, z)
}(x: BigInt{noalias}; y: BigInt; z: int32)
```

## **template** optMulSameInt


```nim
template optMulSameInt{
 x = `*`(x, z)
}(x: BigInt; z: int32)
```

## **template** optMul


```nim
template optMul{
 x = `*`(y, z)
}(x: BigInt{noalias}; y, z: BigInt)
```

## **template** optMulSame


```nim
template optMulSame{
 x = `*`(x, z)
}(x, z: BigInt)
```

## **proc** `shr`


```nim
proc `shr`(x: BigInt; y: int): BigInt
```

## **template** optShr


```nim
template optShr{
 x = y shr z
}(x, y: BigInt; z)
```

## **proc** `shl`


```nim
proc `shl`(x: BigInt; y: int): BigInt
```

## **template** optShl


```nim
template optShl{
 x = y shl z
}(x, y: BigInt; z)
```

## **proc** reset


```nim
proc reset(a: var BigInt)
```

## **proc** `div`


```nim
proc `div`(a: BigInt; b: int32): BigInt
```

## **proc** `div`


```nim
proc `div`(a, b: BigInt): BigInt
```

## **proc** `mod`


```nim
proc `mod`(a: BigInt; b: int32): BigInt
```

## **proc** `mod`


```nim
proc `mod`(a, b: BigInt): BigInt
```

## **proc** divmod


```nim
proc divmod(a: BigInt; b: int32): tuple[q, r: BigInt]
```

## **proc** divmod


```nim
proc divmod(a, b: BigInt): tuple[q, r: BigInt]
```

## **template** optDivMod


```nim
template optDivMod{
 w = y div z
 x = y mod z}(w, x, y, z: BigInt)
```

## **template** optDivMod2


```nim
template optDivMod2{
 w = x div z
 x = x mod z}(w, x, z: BigInt)
```

## **template** optDivMod3


```nim
template optDivMod3{
 w = w div z
 x = w mod z}(w, x, z: BigInt)
```

## **template** optDivMod4


```nim
template optDivMod4{
 w = y mod z
 x = y div z}(w, x, y, z: BigInt)
```

## **template** optDivMod5


```nim
template optDivMod5{
 w = x mod z
 x = x div z}(w, x, z: BigInt)
```

## **template** optDivMod6


```nim
template optDivMod6{
 w = w mod z
 x = w div z}(w, x, z: BigInt)
```

## **proc** `^`


```nim
proc `^`[T](base, exp: T): T
```

## **proc** pow


```nim
proc pow(base: int32 | BigInt; exp: int32 | BigInt): BigInt
```

## **proc** toString


```nim
proc toString(a: BigInt; base: range[2 .. 36] = 10): string
```

## **proc** `$`


```nim
proc `$`(a: BigInt): string
```

## **proc** initBigInt


```nim
proc initBigInt(str: string; base: range[2 .. 36] = 10): BigInt {.raises: [ValueError], tags: [].}
```

## **proc** inc


```nim
proc inc(a: var BigInt; b: BigInt)
```

## **proc** inc


```nim
proc inc(a: var BigInt; b: int32 = 1)
```

## **proc** dec


```nim
proc dec(a: var BigInt; b: BigInt)
```

## **proc** dec


```nim
proc dec(a: var BigInt; b: int32 = 1)
```

## **iterator** countdown


```nim
iterator countdown(a, b: BigInt; step: int32 = 1): BigInt {.inline.}
```

## **iterator** countup


```nim
iterator countup(a, b: BigInt; step: int32 = 1): BigInt {.inline.}
```

## **iterator** `..`


```nim
iterator `..`(a, b: BigInt): BigInt {.inline.}
```

## **iterator** `..&lt;`


```nim
iterator `..<`(a, b: BigInt): BigInt {.inline.}
```
