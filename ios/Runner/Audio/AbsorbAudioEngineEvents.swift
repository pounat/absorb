import Foundation

enum EngineProcessingState: Int {
  case idle = 0
  case loading = 1
  case buffering = 2
  case ready = 3
  case completed = 4
}

struct EngineStateSnapshot {
  let playing: Bool
  let processingState: EngineProcessingState
  let timeControlStatus: Int
  let reasonForWaitingToPlay: String?
}

protocol AbsorbAudioEngineDelegate: AnyObject {
  func engineDidEmitPosition(_ positionS: Double)
  func engineDidChangeState(_ state: EngineStateSnapshot)
  func engineDidLoadDuration(_ durationS: Double?)
  func engineDidChangeTrack(trackIndex: Int, totalTracks: Int)
  func engineDidCompleteBook()
  func engineDidAutoAdvance()
  func engineDidEmitBufferedPosition(_ bufferedPositionS: Double)
  func engineDidError(message: String, code: String?)
}
