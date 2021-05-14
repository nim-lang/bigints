# This is an include file, do not import it directly.
# It is needed as a workaround for Nim's parser for versions <= 1.4.

let aa = 1234567'bi
check $aa == "1234567"

let bb = -1234567'bi
check $bb == "-1234567"

let cc = 123456789012345678'bi
check $cc == "123456789012345678"

let dd = -123456789012345678'bi
check $dd == "-123456789012345678"

let hh = 1234567'bi
let ii = hh.initBigInt
check $hh == $ii

let j = 0xff00'bi
check $j == "65280"
let k = 0b1010101010101010101010101010101010101010'bi
check $k == "733007751850"
let l = 0X123456789ABCDEF'bi
check $l == "81985529216486895"

