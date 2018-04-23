/// HalfFloat implementation by Tobais Due Munk
/// https://gist.github.com/duemunk/181c5f179aeda1718991aa912a931f45

import Darwin

extension UInt16 {
  var halfFloat: Float {
    // 1 bit sign
    // 5 bit exponent
    // 11 bit significand (10 bit explicitly stored)
    let sign = Float((self & 0b1000_0000_0000_0000) >> 15)
    let exponent = Float((self & 0b0111_1100_0000_0000) >> 10)
    let significand = Float(self & 0b0000_0011_1111_1111)

    if exponent == 0b0_0000 {
      if significand == 0 {
        return pow(-1, sign) * 0
      } else {
        // (−1)^signbit × 2^(−14) × 0.significantbits
        let last = 0 + significand / 0b0011_1111_1111
        return pow(-1, sign) * pow(2, -14) * last
      }
    } else if exponent == 0b1_1111 {
      if significand == 0 {
        return pow(-1, sign) * .infinity
      } else {
        return .nan
      }
    } else {
      // (−1)^signbit × 2^(exponent−15) × 1.significantbits
      let last = 1 + significand / 0b0011_1111_1111
      return pow(-1, sign) * pow(2, exponent - 15) * last
    }
  }
}

extension Float {
  var halfFloatBitPattern: UInt16 {
    var value = self

    let signBytes: UInt16
    if value.sign == .plus {
      signBytes = 0b0000_0000_0000_0000
    } else {
      signBytes = 0b1000_0000_0000_0000
      value *= -1
    }

    guard value.isNaN == false else {
      let exponentBytes: UInt16 = 0b1_1111
      let significandBytes: UInt16 = 0
      return signBytes | exponentBytes | significandBytes
    }

    guard value != 0 else {
      return signBytes
    }
    let exponent = log2(value).rounded(.down)
    let exponentBytes: UInt16
    let significandBytes: UInt16
    if exponent == 1 {
      exponentBytes = 0
      let significand = value * 1024
      significandBytes = UInt16(significand)
    } else if exponent == .infinity {
      exponentBytes = 0b1111 << 10
      significandBytes = 0
    } else if exponent <= -15 {
      exponentBytes = 0
      let significand = value * 1024
      significandBytes = UInt16(significand)
    } else {
      exponentBytes = UInt16(exponent + 15) << 10
      value /= pow(2, exponent)
      let significand = (value - 1) * 1024
      significandBytes = UInt16(significand)
    }
    return signBytes | exponentBytes | significandBytes
  }
}
