#include "audio_window_channel.h"

#include <flutter/standard_method_codec.h>
#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>

#include <algorithm>
#include <cstdint>
#include <fstream>
#include <thread>

using Microsoft::WRL::ComPtr;

namespace {

constexpr int kTargetRate = 16000;
constexpr LONGLONG kHnsPerSecond = 10000000;
// The reader's stream selectors are negative enum values taken as DWORDs.
constexpr DWORD kAudioStream =
    static_cast<DWORD>(MF_SOURCE_READER_FIRST_AUDIO_STREAM);
constexpr DWORD kAllStreams = static_cast<DWORD>(MF_SOURCE_READER_ALL_STREAMS);

std::wstring Widen(const std::string& s) {
  if (s.empty()) return std::wstring();
  const int n = MultiByteToWideChar(CP_UTF8, 0, s.data(),
                                    static_cast<int>(s.size()), nullptr, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()),
                      w.data(), n);
  return w;
}

bool WriteWav(const std::string& path, const std::vector<int16_t>& pcm) {
  std::ofstream f(Widen(path), std::ios::binary);
  if (!f) return false;
  const uint32_t data_bytes = static_cast<uint32_t>(pcm.size() * 2);
  auto u32 = [&f](uint32_t v) { f.write(reinterpret_cast<const char*>(&v), 4); };
  auto u16 = [&f](uint16_t v) { f.write(reinterpret_cast<const char*>(&v), 2); };
  f.write("RIFF", 4);
  u32(36 + data_bytes);
  f.write("WAVE", 4);
  f.write("fmt ", 4);
  u32(16);
  u16(1);  // PCM
  u16(1);  // mono
  u32(kTargetRate);
  u32(kTargetRate * 2);
  u16(2);
  u16(16);
  f.write("data", 4);
  u32(data_bytes);
  f.write(reinterpret_cast<const char*>(pcm.data()), data_bytes);
  return static_cast<bool>(f);
}

std::string ReadString(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return std::string();
  if (auto s = std::get_if<std::string>(&it->second)) return *s;
  return std::string();
}

double ReadNumber(const flutter::EncodableMap& args, const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return 0;
  if (auto d = std::get_if<double>(&it->second)) return *d;
  if (auto i = std::get_if<int32_t>(&it->second)) return *i;
  if (auto l = std::get_if<int64_t>(&it->second)) return static_cast<double>(*l);
  return 0;
}

}  // namespace

std::string AudioWindowChannel::DecodeWindow(const std::string& source,
                                             double start, double duration,
                                             const std::string& out) {
  ComPtr<IMFSourceReader> reader;
  if (FAILED(MFCreateSourceReaderFromURL(Widen(source).c_str(), nullptr,
                                         &reader))) {
    return "could not open the audio";
  }
  reader->SetStreamSelection(kAllStreams, FALSE);
  reader->SetStreamSelection(kAudioStream, TRUE);

  ComPtr<IMFMediaType> wanted;
  MFCreateMediaType(&wanted);
  wanted->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
  wanted->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
  wanted->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
  if (FAILED(reader->SetCurrentMediaType(kAudioStream,
                                         nullptr, wanted.Get()))) {
    return "no decoder for this audio";
  }
  ComPtr<IMFMediaType> actual;
  reader->GetCurrentMediaType(kAudioStream, &actual);
  UINT32 channels = 0;
  UINT32 rate = 0;
  actual->GetUINT32(MF_MT_AUDIO_NUM_CHANNELS, &channels);
  actual->GetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, &rate);
  if (channels == 0 || rate == 0) return "unreadable audio format";

  const LONGLONG start_hns = static_cast<LONGLONG>(start * kHnsPerSecond);
  if (start_hns > 0) {
    PROPVARIANT pos;
    PropVariantInit(&pos);
    pos.vt = VT_I8;
    pos.hVal.QuadPart = start_hns;
    reader->SetCurrentPosition(GUID_NULL, pos);
    PropVariantClear(&pos);
  }

  const size_t wanted_frames = static_cast<size_t>(duration * rate);
  std::vector<float> mono;
  mono.reserve(wanted_frames);
  while (mono.size() < wanted_frames) {
    DWORD flags = 0;
    LONGLONG timestamp = 0;
    ComPtr<IMFSample> sample;
    if (FAILED(reader->ReadSample(kAudioStream, 0,
                                  nullptr, &flags, &timestamp, &sample))) {
      return "decoding failed";
    }
    if (flags & MF_SOURCE_READERF_ENDOFSTREAM) break;
    if (!sample) continue;
    ComPtr<IMFMediaBuffer> buffer;
    if (FAILED(sample->ConvertToContiguousBuffer(&buffer))) continue;
    BYTE* data = nullptr;
    DWORD length = 0;
    if (FAILED(buffer->Lock(&data, nullptr, &length))) continue;
    const auto* samples = reinterpret_cast<const int16_t*>(data);
    const size_t frames = length / (2 * channels);
    // A seek lands on the frame before the target; drop the lead-in.
    size_t skip = 0;
    if (timestamp < start_hns) {
      skip = static_cast<size_t>((start_hns - timestamp) * rate / kHnsPerSecond);
      skip = (std::min)(skip, frames);
    }
    for (size_t i = skip; i < frames && mono.size() < wanted_frames; ++i) {
      float sum = 0;
      for (UINT32 c = 0; c < channels; ++c) sum += samples[i * channels + c];
      mono.push_back(sum / channels / 32768.0f);
    }
    buffer->Unlock();
  }
  if (mono.empty()) return "no audio in that window";

  const size_t out_frames =
      static_cast<size_t>(static_cast<double>(mono.size()) * kTargetRate / rate);
  const double step = static_cast<double>(rate) / kTargetRate;
  std::vector<int16_t> pcm(out_frames);
  for (size_t i = 0; i < out_frames; ++i) {
    const double p = i * step;
    const size_t a = (std::min)(static_cast<size_t>(p), mono.size() - 1);
    const size_t b = (std::min)(a + 1, mono.size() - 1);
    const double t = p - static_cast<double>(a);
    float v = static_cast<float>(mono[a] + (mono[b] - mono[a]) * t);
    v = (std::max)(-1.0f, (std::min)(1.0f, v));
    pcm[i] = static_cast<int16_t>(v * 32767.0f);
  }
  return WriteWav(out, pcm) ? std::string() : "could not write the WAV";
}

AudioWindowChannel::AudioWindowChannel(flutter::BinaryMessenger* messenger,
                                       HWND window)
    : state_(std::make_shared<State>()) {
  state_->window = window;
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.barnabas.absorb/transcription",
      &flutter::StandardMethodCodec::GetInstance());
  auto state = state_;
  channel_->SetMethodCallHandler(
      [state](const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                  result) {
        if (call.method_name() != "extractWav") {
          result->NotImplemented();
          return;
        }
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args == nullptr) {
          result->Error("bad_args", "extractWav needs a map");
          return;
        }
        const std::string source = ReadString(*args, "sourcePath");
        const std::string out = ReadString(*args, "outPath");
        const double start = ReadNumber(*args, "startSeconds");
        const double duration = ReadNumber(*args, "durationSeconds");
        Result shared(std::move(result));
        // Decoding a window takes a moment; keep it off the UI thread.
        std::thread([state, shared, source, out, start, duration]() {
          const HRESULT com = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
          std::string error = "Media Foundation is unavailable";
          if (SUCCEEDED(MFStartup(MF_VERSION))) {
            error = DecodeWindow(source, start, duration, out);
            MFShutdown();
          }
          if (SUCCEEDED(com)) CoUninitialize();
          {
            std::lock_guard<std::mutex> lock(state->mutex);
            state->done.push_back({shared, error});
          }
          PostMessage(state->window, kDoneMessage, 0, 0);
        }).detach();
      });
}

void AudioWindowChannel::DrainResults() {
  std::vector<Done> done;
  {
    std::lock_guard<std::mutex> lock(state_->mutex);
    done.swap(state_->done);
  }
  for (auto& d : done) {
    if (d.error.empty()) {
      d.result->Success(flutter::EncodableValue(true));
    } else {
      d.result->Error("extract_failed", d.error);
    }
  }
}
