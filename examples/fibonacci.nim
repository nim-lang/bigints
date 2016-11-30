import tables, bigints

proc fib(x: int; store = {0:0.initBigInt, 1:1.initBigInt}.newTable): BigInt =
  #
  # assumes x an int >= 0
  #
  # returns Fibonacci of x
  #
  if store.hasKey(x):
    result = store[x]
  else:
    result = fib(x - 1, store) + fib(x - 2, store)
    store[x] = result

echo fib(100000)
