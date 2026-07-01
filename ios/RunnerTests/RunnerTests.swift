import AVFoundation
import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testSilenceAnalyzerFindsGuardedSilenceRange() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("caf")
    defer { try? FileManager.default.removeItem(at: url) }

    let sampleRate = 44_100.0
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    let frameCount = AVAudioFrameCount(sampleRate * 3)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
    buffer.frameLength = frameCount

    let samples = buffer.floatChannelData![0]
    for frame in 0..<Int(frameCount) {
      let second = Double(frame) / sampleRate
      if second < 1.0 || second >= 2.0 {
        samples[frame] = sinf(Float(second * 440.0 * 2.0 * .pi)) * 0.25
      } else {
        samples[frame] = 0
      }
    }

    let file = try AVAudioFile(forWriting: url, settings: format.settings)
    try file.write(from: buffer)

    let exp = expectation(description: "analyze silence")
    AbsorbSilenceAnalyzer.shared.analyze(
      url: url,
      headers: [:],
      epoch: 1,
      isCurrent: { $0 == 1 },
      completion: { _, result in
        switch result {
        case .success(let ranges):
          XCTAssertEqual(ranges.count, 1)
          // AVAssetReader returns PCM in chunks, so the detected edges can be
          // displaced by roughly one buffer from the exact tone boundary.
          XCTAssertEqual(ranges[0].start, 1.04, accuracy: 0.15)
          XCTAssertEqual(ranges[0].end, 1.96, accuracy: 0.15)
        case .failure(let error):
          XCTFail("Analyzer failed: \(error)")
        }
        exp.fulfill()
      }
    )
    wait(for: [exp], timeout: 5)
  }

  func testSilenceConfigurationNormalizesUnsafeValues() {
    let configuration = AbsorbSilenceConfiguration(
      thresholdDb: -80,
      minimumSilenceS: 0.1,
      mergeGapS: 1,
      guardS: 1
    )

    XCTAssertEqual(configuration.thresholdDb, -60)
    XCTAssertEqual(configuration.minimumSilenceS, 0.1)
    XCTAssertEqual(configuration.mergeGapS, 0.3)
    XCTAssertEqual(configuration.guardS, 0.04)
  }

}
