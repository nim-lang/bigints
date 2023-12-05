import bigints
import benchy
import random

block: # Bench random generation
  randomize()
  var n = 100
  timeIt "bench Random generation of bigints with 100 limbs":
    keep initRandomBigint(n)
  timeIt "bench Random generation of bigints with 1_000 limbs":
    keep initRandomBigint(n)
  n = 5_000
  timeIt "bench Random generation of bigints with 5_000 limbs":
    keep initRandomBigint(n)
  n = 10_000
  timeIt "bench Random generation of bigints with 10_000 limbs":
    keep initRandomBigint(n)
block: # Bench multiplication
  randomize()
  var n = 100
  timeIt "bench Multiplication of bigints with 100 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a*b
  n = 1_000
  timeIt "bench Multiplication of bigints with 1_000 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a*b
  n = 5_000
  timeIt "bench Multiplication of bigints with 5_000 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a*b
  n = 10_000
  timeIt "bench Multiplication of bigints with 10_000 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a*b
block: # Bench division
  randomize()
  var n = 100
  timeIt "bench Division of bigints with 100 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a div b
  n = 1_000
  timeIt "bench Division of bigints with 1_000 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a div b
  n = 5_000
  timeIt "bench Division of bigints with 5_000 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a div b
  n = 10_000
  timeIt "bench Division of bigints with 10_000 limbs":
    var a: Bigint = initRandomBigint(n)
    var b: Bigint = initRandomBigint(n)
    keep a div b
