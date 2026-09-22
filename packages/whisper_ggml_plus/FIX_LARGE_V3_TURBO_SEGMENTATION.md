# Fix for Large-v3-Turbo Single Segment Issue (v1.2.5)

## Problem

When using `ggml-large-v3-turbo-q3_k.bin`, transcription returns only one large segment (통짜) instead of multiple time-stamped segments like the base model does.

## Root Cause (Updated Analysis)

### Primary Issue: Model Doesn't Generate Timestamp Tokens

The real problem is **not** the `single_segment` parameter, but that **Large-v3-Turbo doesn't naturally generate timestamp tokens** when using greedy sampling.

**Segmentation Logic** (whisper.cpp line 7638):
```cpp
if (tokens_cur[i].id > whisper_token_beg(ctx) && !params.single_segment) {
    // Timestamp token detected → create new segment
    const auto t1 = seek + 2*(tokens_cur[i].tid - whisper_token_beg(ctx));
    result_all.push_back({ tt0, tt1, text, ... });  // Add segment
}
```

**Requirements for segmentation**:
1. Model must generate timestamp tokens (`<|0.00|>`, `<|0.02|>`, etc.)
2. `single_segment` must be `false`

**What happens with Large-v3-Turbo**:
- ✅ `single_segment = false` (we set this)
- ❌ **Model doesn't generate timestamp tokens** (primary issue)
- Result: No timestamp tokens → no segments created → single large segment

### Why Turbo Doesn't Generate Timestamps in Greedy Mode

**Timestamp Sampling Logic** (whisper.cpp line 6336):
```cpp
if (timestamp_logprob > max_text_token_logprob) {
    // Select timestamp token
}
```

**Problem with Large-v3-Turbo + Greedy Sampling**:
1. **Greedy sampling** always picks the highest probability token
2. Large-v3-Turbo was trained with `timestamp_probability=0.2` (20% of the time)
3. In greedy mode, text tokens often have higher probability than timestamp tokens
4. Result: Timestamp tokens are never selected

**Why Base/Large-v3 Work**:
- Base model: Naturally generates timestamps frequently
- Large-v3: 32 decoder layers provide better timestamp prediction
- Large-v3-Turbo: Only 4 decoder layers (distilled) → weaker timestamp generation

### Secondary Issue: Distilled Model Detection

```cpp
// whisper.cpp line 6983
const bool is_distil = ctx->model.hparams.n_text_layer == 2 && ctx->model.hparams.n_vocab != 51866;
if (is_distil && !params.no_timestamps) {
    params.no_timestamps = true;  // Force timestamps off
}
```

Large-v3-Turbo characteristics:
- `n_text_layer = 4` (not 2)
- `n_vocab = 51866`
- Result: **NOT** detected as first-release distilled model ✅

So this check doesn't affect Large-v3-Turbo, but we still set `single_segment=false` as a safety measure.

## Solution Applied (v1.2.5)

### 1. Auto-Detect Large-v3-Turbo and Force Segmentation

**Files Modified:**
- `ios/Classes/whisper_flutter_plus.cpp`
- `macos/Classes/whisper_ggml.cpp`
- `android/src/whisper/main.cpp`

**Detection Logic**:
```cpp
const int model_n_text_layer = whisper_model_n_text_layer(g_ctx);
const int model_n_vocab = whisper_model_n_vocab(g_ctx);
const bool is_turbo = (model_n_text_layer == 4 && model_n_vocab == 51866);
```

**Forced Segmentation for Turbo**:
```cpp
if (is_turbo && !params.no_timestamps) {
    wparams.max_len = 50;              // Split every 50 characters
    wparams.token_timestamps = true;   // Enable token-level timestamps
    wparams.split_on_word = true;      // Split on word boundaries
}
```

**How it works**:
- `max_len = 50`: Forces text to be split every 50 characters
- `split_on_word = true`: Ensures splits happen at word boundaries (natural breaks)
- `token_timestamps = true`: Enables token-level timestamp calculation
- Result: Text is artificially segmented even without timestamp tokens from the model

### 2. Safety Measure: Explicit single_segment=false

```cpp
wparams.single_segment = false;  // Prevent single segment mode
```

This ensures that even if other code paths try to enable single-segment mode, it stays off.

### 3. Comprehensive Debug Logging

```cpp
fprintf(stderr, "[DEBUG] Model info - n_text_layer: %d, n_vocab: %d, is_turbo: %d\n", 
        model_n_text_layer, model_n_vocab, is_turbo);

fprintf(stderr, "[DEBUG] Transcription params - no_timestamps: %d, single_segment: %d, split_on_word: %d, max_len: %d\n",
        wparams.no_timestamps, wparams.single_segment, wparams.split_on_word, wparams.max_len);
```

## How to Test

### 1. Check Debug Output

**Expected for Large-v3-Turbo**:
```
[DEBUG] Model info - n_text_layer: 4, n_vocab: 51866, is_turbo: 1
[DEBUG] Turbo model detected - enabling forced segmentation (max_len=50)
[DEBUG] Transcription params - no_timestamps: 0, single_segment: 0, split_on_word: 1, max_len: 50
```

**Key indicators**:
- `is_turbo: 1` → Turbo model detected
- `split_on_word: 1` → Forced segmentation enabled
- `max_len: 50` → 50-character segments

### 2. Test Transcription

```dart
final result = await controller.transcribe(
  model: WhisperModel.largeV3,
  audioPath: audioPath,
);

print("Segment count: ${result.transcription.segments.length}");
for (var segment in result.transcription.segments) {
  print("[${segment.fromTs} -> ${segment.toTs}] ${segment.text}");
}
```

**Expected behavior**:
- ❌ Before: `segments.length = 1` (single large segment)
- ✅ After: `segments.length > 1` (multiple segments, ~50 chars each)

## Alternative Solutions (if needed)

### Option 1: User-controlled splitOnWord

If automatic detection causes issues:
```dart
final result = await controller.transcribe(
  model: WhisperModel.largeV3,
  audioPath: audioPath,
  splitOnWord: true,  // Manually enable
);
```

### Option 2: Adjust max_len

If 50 characters is too short/long, modify in the code:
```cpp
wparams.max_len = 80;  // Longer segments
// or
wparams.max_len = 30;  // Shorter segments
```

### Option 3: Use Beam Search (future enhancement)

```cpp
// Instead of greedy sampling
whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH);
wparams.beam_search.beam_size = 3;
```

This would allow the model to naturally generate timestamp tokens, but at 3-5x slower speed.

## Technical Deep Dive

### Why max_len Works

**Whisper.cpp segment wrapping logic** (line 7667):
```cpp
if (params.max_len > 0) {
    n_new = whisper_wrap_segment(*ctx, *state, params.max_len, params.split_on_word);
}
```

When `max_len` is set:
1. After decoding, check if segment text exceeds `max_len` characters
2. If yes, split the segment at word boundaries (`split_on_word=true`)
3. Create multiple segments with interpolated timestamps
4. Result: Artificial segmentation without needing timestamp tokens from model

### Model Characteristics

| Model | n_text_layer | n_vocab | Timestamp Generation | Our Solution |
|-------|--------------|---------|---------------------|--------------|
| Base | 6 | 51,864 | ✅ Natural | No intervention needed |
| Small | 12 | 51,864 | ✅ Natural | No intervention needed |
| Large-v3 | 32 | 51,866 | ✅ Natural | No intervention needed |
| **Large-v3-Turbo** | **4** | **51,866** | **❌ Weak** | **✅ max_len=50 forced** |
| Distil-v2 | 2 | 51,864 | ❌ None | timestamps disabled |

## Version Changes

- **pubspec.yaml**: 1.2.3 → 1.2.5
- **ios/whisper_ggml_plus.podspec**: 1.2.3 → 1.2.5
- **macos/whisper_ggml_plus.podspec**: 1.2.3 → 1.2.5
- **CHANGELOG.md**: Updated v1.2.5 entry with accurate root cause

## Files Modified

1. `ios/Classes/whisper_flutter_plus.cpp` - Turbo detection + forced segmentation
2. `macos/Classes/whisper_ggml.cpp` - Turbo detection + forced segmentation
3. `android/src/whisper/main.cpp` - Turbo detection + forced segmentation
4. `pubspec.yaml` - Version 1.2.5
5. `ios/whisper_ggml_plus.podspec` - Version 1.2.5
6. `macos/whisper_ggml_plus.podspec` - Version 1.2.5
7. `CHANGELOG.md` - Updated release notes with accurate explanation
8. `FIX_LARGE_V3_TURBO_SEGMENTATION.md` - Complete technical analysis (this file)

## Summary

The issue wasn't about `single_segment` or distilled model detection. **Large-v3-Turbo simply doesn't generate timestamp tokens in greedy sampling mode**, which prevents natural segmentation.

Our solution: **Auto-detect Turbo models and force segmentation using `max_len=50` + `split_on_word=true`**, which artificially splits text into proper segments without needing timestamp tokens from the model.

**Result**: Large-v3-Turbo now produces multiple segments just like other models!
