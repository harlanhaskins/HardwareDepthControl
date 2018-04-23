import CoreVideo
import AVFoundation

extension CVPixelBuffer {
  subscript(_ x: Int, _ y: Int) -> Float {
    let buffer =
      CVPixelBufferGetBaseAddress(self)!.assumingMemoryBound(to: Float.self)
    let width = CVPixelBufferGetWidth(self)
    let index = x + (y * width)
    CVPixelBufferLockBaseAddress(self, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }

    return buffer[index]
  }
}
