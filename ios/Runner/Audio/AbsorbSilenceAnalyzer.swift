import AVFoundation
import Foundation

struct AbsorbSilenceRange {
  let start: Double
  let end: Double
}

struct AbsorbSilenceConfiguration: Equatable {
  static let defaultSettings = AbsorbSilenceConfiguration(
    thresholdDb: -38,
    minimumSilenceS: 0.25,
    mergeGapS: 0.12,
    guardS: 0.04
  )

  let thresholdDb: Double
  let minimumSilenceS: Double
  let mergeGapS: Double
  let guardS: Double

  init(thresholdDb: Double,
       minimumSilenceS: Double,
       mergeGapS: Double,
       guardS: Double) {
    let normalizedMinimum = min(max(minimumSilenceS, 0.1), 1.0)
    let maximumGuard = max(0, normalizedMinimum / 2.0 - 0.01)
    self.thresholdDb = min(max(thresholdDb, -60), -25)
    self.minimumSilenceS = normalizedMinimum
    self.mergeGapS = min(max(mergeGapS, 0), 0.3)
    self.guardS = min(max(guardS, 0), maximumGuard)
  }

  var amplitudeThreshold: Float {
    powf(10.0, Float(thresholdDb) / 20.0)
  }
}

final class AbsorbSilenceAnalyzer {
  static let shared = AbsorbSilenceAnalyzer()

  private let queue = DispatchQueue(label: "com.barnabas.absorb.silence-analyzer", qos: .utility)

  private init() {}

  func analyze(url: URL,
               headers: [String: String],
               configuration: AbsorbSilenceConfiguration = .defaultSettings,
               epoch: UInt,
               isCurrent: @escaping (UInt) -> Bool,
               completion: @escaping (UInt, Result<[AbsorbSilenceRange], Error>) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { return }
      guard isCurrent(epoch) else { return }

      var options: [String: Any] = [:]
      if !headers.isEmpty {
        options["AVURLAssetHTTPHeaderFieldsKey"] = headers
      }
      let asset = AVURLAsset(url: url, options: options)

      let semaphore = DispatchSemaphore(value: 0)
      var loadedError: NSError?
      var loadStatus: AVKeyValueStatus = .unknown
      asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
        loadStatus = asset.statusOfValue(forKey: "tracks", error: &loadedError)
        semaphore.signal()
      }
      semaphore.wait()

      guard isCurrent(epoch) else { return }
      if let loadedError = loadedError {
        completion(epoch, .failure(loadedError))
        return
      }
      guard loadStatus == .loaded else {
        completion(epoch, .failure(NSError(
          domain: "AbsorbSilenceAnalyzer",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: "Audio tracks not loaded"]
        )))
        return
      }

      do {
        let ranges = try self.readSilenceRanges(asset: asset, configuration: configuration, isCurrent: {
          isCurrent(epoch)
        })
        guard isCurrent(epoch) else { return }
        completion(epoch, .success(ranges))
      } catch {
        guard isCurrent(epoch) else { return }
        completion(epoch, .failure(error))
      }
    }
  }

  private func readSilenceRanges(asset: AVAsset,
                                 configuration: AbsorbSilenceConfiguration,
                                 isCurrent: () -> Bool) throws -> [AbsorbSilenceRange] {
    let reader = try AVAssetReader(asset: asset)
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMIsFloatKey: true,
      AVLinearPCMBitDepthKey: 32,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]
    let output = AVAssetReaderAudioMixOutput(audioTracks: asset.tracks(withMediaType: .audio),
                                            audioSettings: settings)
    output.alwaysCopiesSampleData = false
    guard reader.canAdd(output) else {
      throw NSError(domain: "AbsorbSilenceAnalyzer", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot add PCM output"])
    }
    reader.add(output)
    guard reader.startReading() else {
      throw reader.error ?? NSError(domain: "AbsorbSilenceAnalyzer", code: 2,
                                    userInfo: [NSLocalizedDescriptionKey: "Cannot start reader"])
    }

    var ranges: [AbsorbSilenceRange] = []
    var silenceStart: Double?
    var silenceEnd: Double = 0
    var cursor: Double = 0

    while reader.status == .reading {
      guard isCurrent() else {
        reader.cancelReading()
        return []
      }
      guard let sample = output.copyNextSampleBuffer() else { break }

      let pts = CMSampleBufferGetPresentationTimeStamp(sample)
      let sampleStart = pts.isValid && pts.seconds.isFinite ? pts.seconds : cursor
      var sampleDuration = CMSampleBufferGetDuration(sample).seconds
      if !sampleDuration.isFinite || sampleDuration <= 0 {
        sampleDuration = estimateDuration(sample)
      }
      if !sampleDuration.isFinite || sampleDuration <= 0 {
        sampleDuration = 0
      }
      let sampleEnd = sampleStart + sampleDuration
      cursor = sampleEnd

      guard let level = rms(sample) else {
        reader.cancelReading()
        throw NSError(domain: "AbsorbSilenceAnalyzer", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot read PCM sample data"])
      }

      if level <= configuration.amplitudeThreshold {
        if silenceStart == nil { silenceStart = sampleStart }
        silenceEnd = sampleEnd
      } else if let start = silenceStart {
        appendRange(start: start, end: silenceEnd, minimumSilenceS: configuration.minimumSilenceS, to: &ranges)
        silenceStart = nil
      }
    }

    if let start = silenceStart {
      appendRange(start: start, end: silenceEnd, minimumSilenceS: configuration.minimumSilenceS, to: &ranges)
    }

    if reader.status == .failed {
      throw reader.error ?? NSError(domain: "AbsorbSilenceAnalyzer", code: 3,
                                    userInfo: [NSLocalizedDescriptionKey: "Reader failed"])
    }

    return guardedRanges(
      merge(ranges, maximumGapS: configuration.mergeGapS),
      guardS: configuration.guardS
    )
  }

  private func appendRange(start: Double,
                           end: Double,
                           minimumSilenceS: Double,
                           to ranges: inout [AbsorbSilenceRange]) {
    guard end - start >= minimumSilenceS else { return }
    ranges.append(AbsorbSilenceRange(start: start, end: end))
  }

  private func merge(_ ranges: [AbsorbSilenceRange],
                     maximumGapS: Double) -> [AbsorbSilenceRange] {
    guard var current = ranges.first else { return [] }
    var out: [AbsorbSilenceRange] = []
    for range in ranges.dropFirst() {
      if range.start - current.end <= maximumGapS {
        current = AbsorbSilenceRange(start: current.start, end: max(current.end, range.end))
      } else {
        out.append(current)
        current = range
      }
    }
    out.append(current)
    return out
  }

  private func guardedRanges(_ ranges: [AbsorbSilenceRange],
                             guardS: Double) -> [AbsorbSilenceRange] {
    ranges.compactMap { range in
      let start = range.start + guardS
      let end = range.end - guardS
      guard end > start, end - start >= 0.05 else { return nil }
      return AbsorbSilenceRange(start: start, end: end)
    }
  }

  private func estimateDuration(_ sample: CMSampleBuffer) -> Double {
    guard let format = CMSampleBufferGetFormatDescription(sample) else { return 0 }
    guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format) else { return 0 }
    let sampleRate = asbd.pointee.mSampleRate
    guard sampleRate > 0 else { return 0 }
    return Double(CMSampleBufferGetNumSamples(sample)) / sampleRate
  }

  private func rms(_ sample: CMSampleBuffer) -> Float? {
    guard let buffer = CMSampleBufferGetDataBuffer(sample) else { return nil }
    var lengthAtOffset = 0
    var totalLength = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    let status = CMBlockBufferGetDataPointer(buffer,
                                             atOffset: 0,
                                             lengthAtOffsetOut: &lengthAtOffset,
                                             totalLengthOut: &totalLength,
                                             dataPointerOut: &dataPointer)
    guard status == kCMBlockBufferNoErr,
          let dataPointer = dataPointer,
          totalLength >= MemoryLayout<Float>.size else {
      return nil
    }

    let count = totalLength / MemoryLayout<Float>.size
    if count <= 0 { return nil }

    let sum = dataPointer.withMemoryRebound(to: Float.self, capacity: count) { ptr -> Float in
      var total: Float = 0
      for i in 0..<count {
        let value = ptr[i]
        total += value * value
      }
      return total
    }
    return sqrtf(sum / Float(count))
  }
}
