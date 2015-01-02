# By Cyther606: http://forum.nimrod-lang.org/t/522
# Adapted from: https://github.com/wobine/blackboard101/blob/master/EllipticCurvesPart4-PrivateKeyToPublicKey.py
import bigints, math, strutils

proc `^`(base: int; exp: int): BigInt =
  let base = base.initBigInt
  var exp = exp
  result = 1.initBigInt
  while exp > 0:
    result *= base
    dec(exp)

let
  Pcurve: BigInt = 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1
  N = initBigInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", 16)
  Acurve = 0.initBigInt
  Bcurve = 7.initBigInt
  Gx = initBigInt("55066263022277343669578718895168534326250603453777594175500187360389116729240")
  Gy = initBigInt("32670510020758816978083085130507043184471273380659243275938904335757337482424")
  Gpoint = (Gx, Gy)
  privKey = initBigInt("A0DC65FFCA799873CBEA0AC274015B9526505DAAAED385155425F7337704883E", 16)

proc modinv(a: BigInt): BigInt =
  var
    lm = 1.initBigInt
    hm = 0.initBigInt
    lowm = a mod Pcurve
    highm = Pcurve
  while lowm > 1:
    let
      ratio = highm div lowm
      nm = hm - (lm * ratio)
      temp = highm - (lowm * ratio)
    hm = nm
    highm = temp
    swap hm, lm
    swap highm, lowm
  result = lm mod Pcurve

proc ecAdd(a: tuple, b: tuple): tuple =
  let
    lamAdd = ((b[1] - a[1]) * modinv(b[0] - a[0])) mod Pcurve
    x = (lamAdd * lamAdd - a[0] - b[0]) mod Pcurve
    y = (lamAdd * (a[0] - x) - a[1]) mod Pcurve
  result = (x, y)

proc ecDouble(a: tuple): tuple =
  var
    lam = ((3.initBigInt * a[0] * a[0] + Acurve) * modinv(2.initBigInt * a[1]))
    x = ((lam * lam) - (2.initBigInt * a[0])) mod Pcurve
    y = (lam * (a[0] - x) - a[1]) mod Pcurve
  lam = lam mod Pcurve
  result = (x, y)

proc ecMultiply(genPoint: tuple, scalarHex): tuple =
  if scalarHex == 0 or scalarHex >= N:
    raise newException(Exception, "Invalid Scalar/Private Key")
  var
    scalarBin = scalarHex.toString(base = 2)
    q = genPoint
  for i in 1 .. <scalarBin.len:
    q = ecDouble(q)
    if scalarBin[i] == '1':
      q = ecAdd(q, genPoint)
  result = (q)

proc main() =
  let publicKey = ecMultiply(Gpoint, privKey)

  echo ""
  echo "******* Public Key Generation *********"
  echo ""
  echo "the private key: "
  echo privKey
  echo ""
  echo "the uncompressed public key (not address):"
  echo publicKey
  echo ""
  echo "the uncompressed public key (HEX):"
  echo "04", publicKey[0].toString(base = 16).align(64, '0'), publicKey[1].toString(base = 16).align(64, '0')
  echo ""
  echo "the official Public Key - compressed:"
  echo if publicKey[1] mod 2 == 1: "03" & publicKey[0].toString(base = 16).align(64, '0')
       else: "02" & publicKey[0].toString(base = 16).align(64, '0')

main()
