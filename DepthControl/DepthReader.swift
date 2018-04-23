import Foundation
import AVFoundation

final class DepthReader: NSObject,
  AVCaptureDepthDataOutputDelegate,
  AVCaptureVideoDataOutputSampleBufferDelegate,
  AVCaptureDataOutputSynchronizerDelegate {
  let captureSession = AVCaptureSession()
  let depthDataOutput = AVCaptureDepthDataOutput()
  let videoDataOutput = AVCaptureVideoDataOutput()
  let dataSynchronizer: AVCaptureDataOutputSynchronizer
  let dataQueue = DispatchQueue(label: "com.harlanhaskins.depthreader.data-queue")

  override init() {
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
    captureSession.addOutput(videoDataOutput)

    dataSynchronizer = AVCaptureDataOutputSynchronizer(
      dataOutputs: [
        videoDataOutput,
        depthDataOutput
      ]
    )

    super.init()

    depthDataOutput.setDelegate(self, callbackQueue: dataQueue)
    videoDataOutput.setSampleBufferDelegate(self, queue: dataQueue)
    dataSynchronizer.setDelegate(self, queue: dataQueue)
  }

  func dataOutputSynchronizer(
    _ synchronizer: AVCaptureDataOutputSynchronizer,
    didOutput collection: AVCaptureSynchronizedDataCollection
  ) {
    guard
      let depth = collection[depthDataOutput] as? AVCaptureSynchronizedDepthData,
      let video = collection[videoDataOutput] as? AVCaptureSynchronizedSampleBufferData else {
      print("Missing either depth or video")
      return
    }

    guard !depth.depthDataWasDropped && !video.sampleBufferWasDropped else {
      print("video dropped: \(video.droppedReason)")
      print("depth dropped: \(depth.droppedReason)")
      return
    }

    let convertedData = depth.depthData.converting(
      toDepthDataType: kCVPixelFormatType_DisparityFloat32
    )

    let buffer = convertedData.depthDataMap
    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    print("center depth: \(buffer[width / 2, height / 2])")
  }
}
