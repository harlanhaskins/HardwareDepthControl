import CoreVideo
import AVFoundation

extension CVPixelBuffer {
  subscript(_ x: Int, _ y: Int) -> Float {
    return withLockedBaseAddress {
      guard let addr = baseAddress else { return 0 }
      let buffer = addr.assumingMemoryBound(to: Float.self)
      let index = x + (y * width)
      return buffer[index]
    }
  }

  var width: Int {
    return CVPixelBufferGetWidth(self)
  }

  var height: Int {
    return CVPixelBufferGetHeight(self)
  }

  var baseAddress: UnsafeMutableRawPointer? {
    return CVPixelBufferGetBaseAddress(self)
  }

  func withLockedBaseAddress<T>(
    flags: CVPixelBufferLockFlags = .readOnly,
    _ f: () throws -> T
  ) rethrows -> T {
    CVPixelBufferLockBaseAddress(self, flags)
    defer { CVPixelBufferUnlockBaseAddress(self, flags) }

    return try f()
  }

  func normalize() {
    withLockedBaseAddress(flags: []) {
      let floatPtr = baseAddress!.assumingMemoryBound(to: Float.self)
      let width = self.width
      let height = self.height
      let floatBuffer = UnsafeBufferPointer(start: floatPtr, count: width * height)
      var minValue: Float = .greatestFiniteMagnitude
      var maxValue: Float = .leastNormalMagnitude
      for f in floatBuffer {
        minValue = min(minValue, f)
        maxValue = max(maxValue, f)
      }
      let range = maxValue - minValue
      for y in 0 ..< height {
        for x in 0 ..< width {
          let pixel = floatBuffer[y * width + x]
          floatPtr[y * width + x] = (pixel - minValue) / range
        }
      }
    }
  }
}
