#ifndef RUNNER_MEDIA_CONTROLS_CHANNEL_H_
#define RUNNER_MEDIA_CONTROLS_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Storage.Streams.h>

#include <memory>
#include <mutex>
#include <string>

// Windows side of com.barnabas.absorb/media_controls: the System Media
// Transport Controls, so the media overlay shows the playing book with its
// cover, and the keyboard media keys and headphone buttons reach the player.
// Android and iOS get this from audio_service, which has no Windows side.
class MediaControlsChannel {
 public:
  // Posted to the window from the system's thread on a button press or a
  // seek from the overlay, and from the thumbnail loader when the cover is
  // ready; the window calls the matching method so the work lands on the
  // platform thread.
  static constexpr UINT kButtonMessage = WM_APP + 0x42;
  static constexpr UINT kSeekMessage = WM_APP + 0x43;
  static constexpr UINT kThumbnailMessage = WM_APP + 0x44;

  MediaControlsChannel(flutter::BinaryMessenger* messenger, HWND window);
  ~MediaControlsChannel();

  void DispatchButton(WPARAM button);
  void DispatchSeek(LPARAM position_ms);
  void ApplyThumbnail();

 private:
  struct Thumbnail {
    std::mutex mutex;
    std::wstring path;
    winrt::Windows::Storage::Streams::RandomAccessStreamReference stream{
        nullptr};
  };

  void HandleCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void Update(const flutter::EncodableMap& args);
  void Clear();
  void LoadThumbnail(const std::wstring& path);

  HWND window_;
  winrt::Windows::Media::SystemMediaTransportControls smtc_{nullptr};
  winrt::event_token button_token_{};
  winrt::event_token seek_token_{};
  std::wstring thumbnail_path_;
  std::shared_ptr<Thumbnail> thumbnail_ = std::make_shared<Thumbnail>();
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_MEDIA_CONTROLS_CHANNEL_H_
