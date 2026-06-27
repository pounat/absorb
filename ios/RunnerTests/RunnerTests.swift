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
          XCTAssertEqual(ranges[0].start, 1.06, accuracy: 0.08)
          XCTAssertEqual(ranges[0].end, 1.94, accuracy: 0.08)
        case .failure(let error):
          XCTFail("Analyzer failed: \(error)")
        }
        exp.fulfill()
      }
    )
    wait(for: [exp], timeout: 5)
  }

}
