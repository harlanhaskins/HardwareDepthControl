import Foundation
import AVFoundation
import CoreImage

protocol DepthReaderDelegate: AnyObject {
  func depthReader(_ depthReader: DepthReader, didOutputDepthImage image: CIImage)
}

final class DepthReader: NSObject, AVCaptureDepthDataOutputDelegate {
  let captureSession = AVCaptureSession()
  let depthDataOutput = AVCaptureDepthDataOutput()
  let dataQueue = DispatchQueue(label: "com.harlanhaskins.depthreader.data-queue")

  weak var delegate: DepthReaderDelegate?

  override init() {
    captureSession.beginConfiguration()
    captureSession.sessionPreset = .vga640x480
    depthDataOutput.isFilteringEnabled = true

    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInTrueDepthCamera],
      mediaType: .depthData,
      position: .front
    )
    let device = discoverySession.devices.first!
    let input = try! AVCaptureDeviceInput(device: device)
    captureSession.addInput(input)
    captureSession.addOutput(depthDataOutput)

    if let connection = depthDataOutput.connection(with: .depthData) {
      connection.isEnabled = true
      connection.videoOrientation = .landscapeRight
    }

    super.init()

    depthDataOutput.setDelegate(self, callbackQueue: dataQueue)
    captureSession.commitConfiguration()

    captureSession.startRunning()
  }

  func depthDataOutput(
    _ output: AVCaptureDepthDataOutput,
    didOutput depthData: AVDepthData,
    timestamp: CMTime,
    connection: AVCaptureConnection
    ) {

    let convertedDepth: AVDepthData

    // 2
    if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
      convertedDepth = depthData.converting(
        toDepthDataType: kCVPixelFormatType_DisparityFloat32
      )
    } else {
      convertedDepth = depthData
    }

    // 3
    let pixelBuffer = convertedDepth.depthDataMap

    // 4
    pixelBuffer.normalize()
    let width = Float(pixelBuffer.width)
    let height = pixelBuffer.height

    let rightDepth = pixelBuffer[Int(width * 0.25), height / 2]
    let leftDepth = pixelBuffer[Int(width * 0.75), height / 2]
    print("left: \(leftDepth), right: \(rightDepth)")

    // 5
    let depthMap = CIImage(cvPixelBuffer: pixelBuffer)

    // 6
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      self.delegate?.depthReader(self, didOutputDepthImage: depthMap)
    }
  }
}
