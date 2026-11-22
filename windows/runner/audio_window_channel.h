#ifndef RUNNER_AUDIO_WINDOW_CHANNEL_H_
#define RUNNER_AUDIO_WINDOW_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <mutex>
#include <string>
#include <vector>

// Windows side of com.barnabas.absorb/transcription: decodes a time window of
// an audio file into the 16kHz mono 16-bit WAV whisper.cpp reads, with Media
// Foundation, so nothing extra ships. Android does the same with MediaCodec
// (AudioWindowExtractor.kt) and iOS with AVAssetReader.
class AudioWindowChannel {
 public:
  // Posted to the window when a decode finishes; the window calls
  // DrainResults() so the reply goes out on the platform thread.
  static constexpr UINT kDoneMessage = WM_APP + 0x41;

  AudioWindowChannel(flutter::BinaryMessenger* messenger, HWND window);

  void DrainResults();

  // Decodes [start, start + duration) of |source| into a WAV at |out|.
  // Returns an empty string on success, otherwise what went wrong.
  static std::string DecodeWindow(const std::string& source, double start,
                                  double duration, const std::string& out);

 private:
  using Result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>;
  struct Done {
    Result result;
    std::string error;
  };
  // Shared with the worker threads, which can outlive a call.
  struct State {
    HWND window;
    std::mutex mutex;
    std::vector<Done> done;
  };

  std::shared_ptr<State> state_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_AUDIO_WINDOW_CHANNEL_H_
