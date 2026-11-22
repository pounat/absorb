#include "media_controls_channel.h"

#include <flutter/standard_method_codec.h>
#include <systemmediatransportcontrolsinterop.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.h>

#include <chrono>
#include <thread>

using winrt::Windows::Media::MediaPlaybackStatus;
using winrt::Windows::Media::MediaPlaybackType;
using winrt::Windows::Media::SystemMediaTransportControls;
using winrt::Windows::Media::SystemMediaTransportControlsButton;
using winrt::Windows::Media::SystemMediaTransportControlsTimelineProperties;
using winrt::Windows::Storage::StorageFile;
using winrt::Windows::Storage::Streams::RandomAccessStreamReference;

namespace {

std::wstring Widen(const std::string& s) {
  if (s.empty()) return std::wstring();
  const int n = MultiByteToWideChar(CP_UTF8, 0, s.data(),
                                    static_cast<int>(s.size()), nullptr, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()),
                      w.data(), n);
  return w;
}

std::string ReadString(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return std::string();
  const auto* s = std::get_if<std::string>(&it->second);
  return s ? *s : std::string();
}

bool ReadBool(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return false;
  const auto* b = std::get_if<bool>(&it->second);
  return b ? *b : false;
}

double ReadDouble(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return 0.0;
  if (const auto* d = std::get_if<double>(&it->second)) return *d;
  if (const auto* i = std::get_if<int32_t>(&it->second)) return *i;
  if (const auto* l = std::get_if<int64_t>(&it->second)) {
    return static_cast<double>(*l);
  }
  return 0.0;
}

const char* ButtonName(SystemMediaTransportControlsButton button) {
  switch (button) {
    case SystemMediaTransportControlsButton::Play:
      return "play";
    case SystemMediaTransportControlsButton::Pause:
      return "pause";
    case SystemMediaTransportControlsButton::Stop:
      return "stop";
    case SystemMediaTransportControlsButton::FastForward:
      return "fastForward";
    case SystemMediaTransportControlsButton::Rewind:
      return "rewind";
    case SystemMediaTransportControlsButton::Next:
      return "next";
    case SystemMediaTransportControlsButton::Previous:
      return "previous";
    default:
      return nullptr;
  }
}

}  // namespace

MediaControlsChannel::MediaControlsChannel(flutter::BinaryMessenger* messenger,
                                           HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.barnabas.absorb/media_controls",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleCall(call, std::move(result));
      });

  try {
    auto interop = winrt::get_activation_factory<
        SystemMediaTransportControls, ISystemMediaTransportControlsInterop>();
    winrt::check_hresult(interop->GetForWindow(
        window_, winrt::guid_of<SystemMediaTransportControls>(),
        winrt::put_abi(smtc_)));
    smtc_.IsEnabled(false);
    smtc_.IsPlayEnabled(true);
    smtc_.IsPauseEnabled(true);
    smtc_.IsStopEnabled(true);
    smtc_.IsNextEnabled(true);
    smtc_.IsPreviousEnabled(true);
    // The system raises these off the platform thread; only the window
    // handle is captured so a press after teardown finds nothing to touch.
    const HWND target = window_;
    button_token_ = smtc_.ButtonPressed(
        [target](const SystemMediaTransportControls&, const auto& args) {
          PostMessage(target, kButtonMessage,
                      static_cast<WPARAM>(args.Button()), 0);
        });
    seek_token_ = smtc_.PlaybackPositionChangeRequested(
        [target](const SystemMediaTransportControls&, const auto& args) {
          const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                              args.RequestedPlaybackPosition())
                              .count();
          PostMessage(target, kSeekMessage, 0, static_cast<LPARAM>(ms));
        });
  } catch (...) {
    smtc_ = nullptr;
  }
}

MediaControlsChannel::~MediaControlsChannel() {
  if (!smtc_) return;
  try {
    smtc_.ButtonPressed(button_token_);
    smtc_.PlaybackPositionChangeRequested(seek_token_);
    smtc_.IsEnabled(false);
  } catch (...) {
  }
}

void MediaControlsChannel::HandleCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!smtc_) {
    result->Success(flutter::EncodableValue(false));
    return;
  }
  try {
    if (call.method_name() == "update") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args) Update(*args);
      result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "clear") {
      Clear();
      result->Success(flutter::EncodableValue(true));
    } else {
      result->NotImplemented();
    }
  } catch (const winrt::hresult_error& e) {
    result->Error("smtc", winrt::to_string(e.message()));
  } catch (...) {
    result->Error("smtc", "media controls update failed");
  }
}

void MediaControlsChannel::Update(const flutter::EncodableMap& args) {
  auto updater = smtc_.DisplayUpdater();
  updater.Type(MediaPlaybackType::Music);
  auto music = updater.MusicProperties();
  music.Title(Widen(ReadString(args, "title")));
  music.Artist(Widen(ReadString(args, "artist")));
  music.AlbumTitle(Widen(ReadString(args, "album")));

  const auto thumbnail = Widen(ReadString(args, "thumbnail"));
  if (thumbnail != thumbnail_path_) {
    thumbnail_path_ = thumbnail;
    if (thumbnail.empty()) {
      updater.Thumbnail(nullptr);
    } else {
      LoadThumbnail(thumbnail);
    }
  }
  updater.Update();

  const bool playing = ReadBool(args, "playing");
  smtc_.PlaybackStatus(playing ? MediaPlaybackStatus::Playing
                               : MediaPlaybackStatus::Paused);
  const double rate = ReadDouble(args, "rate");
  if (rate > 0) smtc_.PlaybackRate(rate);

  const auto position = std::chrono::milliseconds(
      static_cast<int64_t>(ReadDouble(args, "position")));
  const auto duration = std::chrono::milliseconds(
      static_cast<int64_t>(ReadDouble(args, "duration")));
  SystemMediaTransportControlsTimelineProperties timeline;
  timeline.StartTime(std::chrono::milliseconds(0));
  timeline.MinSeekTime(std::chrono::milliseconds(0));
  timeline.Position(position);
  timeline.MaxSeekTime(duration);
  timeline.EndTime(duration);
  smtc_.UpdateTimelineProperties(timeline);
  smtc_.IsEnabled(true);
}

void MediaControlsChannel::Clear() {
  thumbnail_path_.clear();
  smtc_.PlaybackStatus(MediaPlaybackStatus::Closed);
  auto updater = smtc_.DisplayUpdater();
  updater.ClearAll();
  updater.Update();
  smtc_.IsEnabled(false);
}

// Opening the file goes through an async WinRT call that must not be waited
// on from the platform thread, so a worker does it and posts back.
void MediaControlsChannel::LoadThumbnail(const std::wstring& path) {
  auto shared = thumbnail_;
  const HWND target = window_;
  std::thread([shared, target, path]() {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    RandomAccessStreamReference stream{nullptr};
    try {
      auto file =
          StorageFile::GetFileFromPathAsync(winrt::hstring(path)).get();
      stream = RandomAccessStreamReference::CreateFromFile(file);
    } catch (...) {
    }
    {
      std::lock_guard<std::mutex> lock(shared->mutex);
      shared->path = path;
      shared->stream = stream;
    }
    PostMessage(target, kThumbnailMessage, 0, 0);
    winrt::uninit_apartment();
  }).detach();
}

void MediaControlsChannel::ApplyThumbnail() {
  if (!smtc_) return;
  RandomAccessStreamReference stream{nullptr};
  {
    std::lock_guard<std::mutex> lock(thumbnail_->mutex);
    // A newer cover may have been asked for while this one loaded.
    if (thumbnail_->path != thumbnail_path_) return;
    stream = thumbnail_->stream;
  }
  if (!stream) return;
  try {
    auto updater = smtc_.DisplayUpdater();
    updater.Thumbnail(stream);
    updater.Update();
  } catch (...) {
  }
}

void MediaControlsChannel::DispatchButton(WPARAM button) {
  if (!channel_) return;
  const char* name =
      ButtonName(static_cast<SystemMediaTransportControlsButton>(button));
  if (!name) return;
  channel_->InvokeMethod("button",
                         std::make_unique<flutter::EncodableValue>(name));
}

void MediaControlsChannel::DispatchSeek(LPARAM position_ms) {
  if (!channel_) return;
  channel_->InvokeMethod("seek", std::make_unique<flutter::EncodableValue>(
                                     static_cast<int64_t>(position_ms)));
}
