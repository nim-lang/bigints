# By Cyther606: https://forum.nim-lang.org/t/522
# Adapted from: https://github.com/wobine/blackboard101/blob/master/EllipticCurvesPart4-PrivateKeyToPublicKey.py
import bigints
import std/[math, strformat]

const
  one = initBigInt(1)
  two = initBigInt(2)
  zero = initBigInt(0)

proc `^`(base: int; exp: int): BigInt = pow(base.initBigInt, exp)

# Specs of the Bitcoin's curve - secp256k1
const
  primeCurve: BigInt = 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - one
  numberPoints = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141'bi
  Acurve = zero # with Bcurve = 7, coefficients in the elliptic curve equation y^2 = x^3 + Acurve * x + Bcurve
  Gx = 55066263022277343669578718895168534326250603453777594175500187360389116729240'bi
  Gy = 32670510020758816978083085130507043184471273380659243275938904335757337482424'bi
  Gpoint = (Gx, Gy)
  privKey = 0xA0DC65FFCA799873CBEA0AC274015B9526505DAAAED385155425F7337704883E'bi

proc ecAdd(a: tuple, b: tuple): (BigInt, BigInt) =
  let
    lamAdd = ((b[1] - a[1]) * invmod((b[0] - a[0]), primeCurve)) mod primeCurve
    x = (lamAdd * lamAdd - a[0] - b[0]) mod primeCurve
    y = (lamAdd * (a[0] - x) - a[1]) mod primeCurve
  result = (x, y)

proc ecDouble(a: tuple): (BigInt, BigInt) =
  var
    lam = (3.initBigInt * a[0] * a[0] + Acurve) * invmod(2.initBigInt * a[1], primeCurve)
    x = ((lam * lam) - (2.initBigInt * a[0])) mod primeCurve
    y = (lam * (a[0] - x) - a[1]) mod primeCurve
  lam = lam mod primeCurve
  result = (x, y)

proc ecMultiply(genPoint: tuple, scalarHex: BigInt): (BigInt, BigInt) =
  if scalarHex == zero or scalarHex >= numberPoints:
    raise newException(Exception, "Invalid Scalar/Private Key")
  var
    scalarBin = scalarHex.toString(base = 2)
    q = genPoint
  for i in 1 ..< scalarBin.len:
    q = ecDouble(q)
    if scalarBin[i] == '1':
      q = ecAdd(q, genPoint)
  result = q

proc main() =
  let publicKey = ecMultiply(Gpoint, privKey)

  echo &"""
******* Public Key Generation *********

the private key:
{privKey}

the uncompressed public key (not address):
{publicKey}

the uncompressed public key (HEX):
04{publicKey[0].toString(base = 16):0>64}{publicKey[1].toString(base = 16):0>64}

the official Public Key - compressed:
{(if publicKey[1] mod two == one: "03" & publicKey[0].toString(base = 16)
  else: "02" & publicKey[0].toString(base = 16)):0>64}
"""

main()
