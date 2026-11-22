#import "./include/just_audio/AudioEQProcessor.h"
#import <MediaToolbox/MediaToolbox.h>
#import <Accelerate/Accelerate.h>
#import <stdatomic.h>
#import <math.h>

// ── Constants ──

#define EQ_NUM_BANDS    5
#define MAX_CHANNELS    2

static const float kBandFrequencies[EQ_NUM_BANDS] = {60.0f, 230.0f, 910.0f, 3600.0f, 14000.0f};
static const float kDefaultQ = 1.4f;  // Q factor for peaking EQ bands

// ── Biquad filter coefficients (normalised: a0 = 1) ──

typedef struct {
    float b0, b1, b2, a1, a2;
} BiquadCoeffs;

// ── Per-channel delay line for one biquad section ──

typedef struct {
    float x1, x2;  // input delay
    float y1, y2;  // output delay
} BiquadDelay;

// ── Shared atomic parameter block ──
// Written from main thread, read from real-time audio thread.

typedef struct {
    _Atomic(int)  enabled;
    _Atomic(int)  mono;
    _Atomic(int)  loudnessGainMb;  // millibels
    _Atomic(int)  bassBoostStrength; // 0-1000

    // Band levels in millibels (-1500 to +1500)
    _Atomic(int)  bandLevels[EQ_NUM_BANDS];

    // Coefficient version counter - bumped whenever coefficients change.
    _Atomic(int)  coeffVersion;
} EQParams;

// The loudness slider as an automatic level, the way a car radio's auto
// volume works. Quiet narration is pulled up toward a target peak and loud
// narration is left alone, so every book comes out at about the same level;
// the slider caps how much gain may be added, and at zero nothing is added.
// The level is followed on speech only: a short-term peak more than 30 dB
// under the recent level is a pause, and the gain holds through it instead
// of creeping up and bursting on the next sentence. Gain drops within 10 ms
// when a louder passage arrives and climbs at 8 dB a second when a quieter
// one does. Same algorithm as the Android Leveler in just_audio.
typedef struct {
    float fastCoef;
    double followCoef;
    float dropCoef;
    float riseStep;
    float fast;
    double envelope;
    float gain;
} Leveler;

static const float kLevelerTarget = 0.708f;
static const float kLevelerPauseRatio = 0.0316f;
static const float kLevelerFloor = 0.001f;

// ── Per-tap context (allocated in tapInit, freed in tapFinalize) ──

typedef struct {
    BiquadDelay delays[EQ_NUM_BANDS][MAX_CHANNELS];
    BiquadDelay bassDelay[MAX_CHANNELS];  // bass boost shelf filter
    BiquadCoeffs coeffs[EQ_NUM_BANDS];
    BiquadCoeffs bassCoeffs;
    Leveler leveler;
    float sampleRate;
    int numChannels;
    int lastCoeffVersion;
} TapContext;

// ── Singleton storage ──

static EQParams sParams;

static void levelerPrepare(Leveler *l, float Fs) {
    l->fastCoef = expf(-1.0f / (0.03f * Fs));
    l->followCoef = exp(-1.0 / (1.0 * Fs));
    l->dropCoef = 1.0f - expf(-1.0f / (0.01f * Fs));
    l->riseStep = powf(10.0f, 8.0f / 20.0f / Fs);
    l->fast = 0.0f;
    l->envelope = 0.0;
    l->gain = 1.0f;
}

/// The gain for one frame whose loudest channel has magnitude peak, with
/// maxGain the most the slider allows (1 = off).
static inline float levelerNext(Leveler *l, float peak, float maxGain) {
    l->fast = peak > l->fast ? peak : l->fast * l->fastCoef;
    if (l->fast >= l->envelope) {
        l->envelope = l->fast;
    } else if (l->fast > l->envelope * kLevelerPauseRatio) {
        l->envelope *= l->followCoef;
        if (l->envelope < l->fast) l->envelope = l->fast;
    }
    float wanted;
    if (l->envelope < kLevelerFloor) {
        wanted = fminf(l->gain, maxGain);
    } else {
        wanted = (float)fmin(maxGain, fmax(1.0, kLevelerTarget / l->envelope));
    }
    if (wanted < l->gain) {
        l->gain += (wanted - l->gain) * l->dropCoef;
        if (l->gain - wanted < 1e-4f) l->gain = wanted;
    } else if (wanted > l->gain) {
        l->gain = fminf(wanted, l->gain * l->riseStep);
    }
    return l->gain;
}

// The DAC clips at full scale, so the overshoot in the 10 ms before the
// gain has dropped for a sudden loud passage is clamped here.
static inline float levelerClamp(float sample) {
    return fmaxf(-1.0f, fminf(1.0f, sample));
}

// ── Biquad coefficient calculation ──

/// Peaking EQ filter coefficients (constant-Q).
static BiquadCoeffs peakingEQ(float f0, float dBGain, float Q, float Fs) {
    BiquadCoeffs c = {1, 0, 0, 0, 0};
    if (Fs <= 0) return c;

    float A     = powf(10.0f, dBGain / 40.0f);
    float w0    = 2.0f * M_PI * f0 / Fs;
    float sinw  = sinf(w0);
    float cosw  = cosf(w0);
    float alpha = sinw / (2.0f * Q);

    float a0 = 1.0f + alpha / A;
    c.b0 = (1.0f + alpha * A) / a0;
    c.b1 = (-2.0f * cosw) / a0;
    c.b2 = (1.0f - alpha * A) / a0;
    c.a1 = (-2.0f * cosw) / a0;
    c.a2 = (1.0f - alpha / A) / a0;
    return c;
}

/// Low-shelf filter coefficients for bass boost.
static BiquadCoeffs lowShelf(float f0, float dBGain, float Fs) {
    BiquadCoeffs c = {1, 0, 0, 0, 0};
    if (Fs <= 0) return c;

    float A     = powf(10.0f, dBGain / 40.0f);
    float w0    = 2.0f * M_PI * f0 / Fs;
    float sinw  = sinf(w0);
    float cosw  = cosf(w0);
    float alpha = sinw / 2.0f * sqrtf((A + 1.0f / A) * (1.0f / 0.7071f - 1.0f) + 2.0f);
    float sqrtA2alpha = 2.0f * sqrtf(A) * alpha;

    float a0 = (A + 1.0f) + (A - 1.0f) * cosw + sqrtA2alpha;
    c.b0 = (A * ((A + 1.0f) - (A - 1.0f) * cosw + sqrtA2alpha)) / a0;
    c.b1 = (2.0f * A * ((A - 1.0f) - (A + 1.0f) * cosw)) / a0;
    c.b2 = (A * ((A + 1.0f) - (A - 1.0f) * cosw - sqrtA2alpha)) / a0;
    c.a1 = (-2.0f * ((A - 1.0f) + (A + 1.0f) * cosw)) / a0;
    c.a2 = ((A + 1.0f) + (A - 1.0f) * cosw - sqrtA2alpha) / a0;
    return c;
}

// ── Inline biquad processing ──

static inline float processBiquad(BiquadCoeffs *c, BiquadDelay *d, float x) {
    float y = c->b0 * x + c->b1 * d->x1 + c->b2 * d->x2
                         - c->a1 * d->y1 - c->a2 * d->y2;
    d->x2 = d->x1;
    d->x1 = x;
    d->y2 = d->y1;
    d->y1 = y;
    return y;
}

// ── Rebuild coefficients in tap context from current params ──

static void rebuildCoefficients(TapContext *ctx) {
    float Fs = ctx->sampleRate;
    // Clamp band frequencies below Nyquist with 5% headroom. Computing a
    // peaking biquad at f0 >= Fs/2 puts the filter poles outside the unit
    // circle, the filter blows up, samples turn into NaN, and the output
    // goes silent. This was the root cause of "Red Rising plays but no
    // sound" reports - low-bitrate AAC m4b decodes to 22050Hz so the
    // 14kHz band tripped the instability.
    float maxBandHz = (Fs * 0.5f) * 0.95f;
    for (int i = 0; i < EQ_NUM_BANDS; i++) {
        float dBGain = (float)atomic_load_explicit(&sParams.bandLevels[i], memory_order_relaxed) / 100.0f;
        float bandHz = kBandFrequencies[i];
        if (bandHz >= maxBandHz) {
            // Above Nyquist - use unity (passthrough) so the filter is stable.
            BiquadCoeffs unity = {1.0f, 0.0f, 0.0f, 0.0f, 0.0f};
            ctx->coeffs[i] = unity;
        } else {
            ctx->coeffs[i] = peakingEQ(bandHz, dBGain, kDefaultQ, Fs);
        }
    }

    // Bass boost: low shelf at 120 Hz, gain 0-12 dB mapped from strength 0-1000
    int bassStrength = atomic_load_explicit(&sParams.bassBoostStrength, memory_order_relaxed);
    float bassdB = (float)bassStrength / 1000.0f * 12.0f;
    if (120.0f >= maxBandHz) {
        BiquadCoeffs unity = {1.0f, 0.0f, 0.0f, 0.0f, 0.0f};
        ctx->bassCoeffs = unity;
    } else {
        ctx->bassCoeffs = lowShelf(120.0f, bassdB, Fs);
    }

    ctx->lastCoeffVersion = atomic_load_explicit(&sParams.coeffVersion, memory_order_relaxed);
}

// ── MTAudioProcessingTap C callbacks ──

static void tapInit(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
    // Allocate per-tap context
    TapContext *ctx = (TapContext *)calloc(1, sizeof(TapContext));
    *tapStorageOut = ctx;
}

static void tapFinalize(MTAudioProcessingTapRef tap) {
    TapContext *ctx = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    if (ctx) free(ctx);
}

// Diagnostics callback set by AppDelegate so format info from tapPrepare
// can land in absorb's in-app log via the Flutter widget channel. NSLog
// alone only shows in Xcode/Console.app on a Mac.
static void (^sFormatLogger)(NSString *) = NULL;

static void tapPrepare(MTAudioProcessingTapRef tap,
                       CMItemCount maxFrames,
                       const AudioStreamBasicDescription *processingFormat) {
    TapContext *ctx = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    if (!ctx) return;

    ctx->sampleRate = (float)processingFormat->mSampleRate;
    ctx->numChannels = (int)processingFormat->mChannelsPerFrame;
    int truncated = 0;
    if (ctx->numChannels > MAX_CHANNELS) {
        truncated = ctx->numChannels;
        ctx->numChannels = MAX_CHANNELS;
    }

    // Zero delay lines
    memset(ctx->delays, 0, sizeof(ctx->delays));
    memset(ctx->bassDelay, 0, sizeof(ctx->bassDelay));
    levelerPrepare(&ctx->leveler, ctx->sampleRate);

    // Build initial coefficients
    rebuildCoefficients(ctx);

    // Diagnostics: dump the audio format so we can correlate "tap enabled
    // produces silence" reports to specific format fingerprints (e.g. low
    // bitrate AAC at 22050Hz mono). Format is the post-decode PCM the tap
    // actually receives, not the source file's compressed format.
    int enabled = atomic_load_explicit(&sParams.enabled, memory_order_relaxed);
    UInt32 fmtID = processingFormat->mFormatID;
    char fmtIDChars[5] = {
        (char)((fmtID >> 24) & 0xff),
        (char)((fmtID >> 16) & 0xff),
        (char)((fmtID >> 8) & 0xff),
        (char)(fmtID & 0xff),
        0
    };
    UInt32 flags = processingFormat->mFormatFlags;
    NSString *line = [NSString stringWithFormat:
        @"[EQDiag] tapPrepare enabled=%d sampleRate=%.1f channels=%u (truncated_from=%d) "
        @"formatID='%s' flags=0x%x [%s%s%s%s%s%s] bitsPerChannel=%u "
        @"bytesPerFrame=%u framesPerPacket=%u maxFrames=%lld",
        enabled,
        processingFormat->mSampleRate,
        (unsigned)processingFormat->mChannelsPerFrame,
        truncated,
        fmtIDChars,
        (unsigned)flags,
        (flags & 0x1) ? "Float " : "",
        (flags & 0x2) ? "BigEndian " : "",
        (flags & 0x4) ? "SignedInt " : "",
        (flags & 0x8) ? "Packed " : "",
        (flags & 0x10) ? "AlignedHigh " : "",
        (flags & 0x20) ? "NonInterleaved" : "Interleaved",
        (unsigned)processingFormat->mBitsPerChannel,
        (unsigned)processingFormat->mBytesPerFrame,
        (unsigned)processingFormat->mFramesPerPacket,
        (long long)maxFrames];
    NSLog(@"%@", line);
    if (sFormatLogger) sFormatLogger(line);
}

static void tapUnprepare(MTAudioProcessingTapRef tap) {
    // Nothing to clean up beyond what tapFinalize handles
}

static void tapProcess(MTAudioProcessingTapRef tap,
                       CMItemCount numberFrames,
                       MTAudioProcessingTapFlags flags,
                       AudioBufferList *bufferListInOut,
                       CMItemCount *numberFramesOut,
                       MTAudioProcessingTapFlags *flagsOut) {
    // First, get the source audio into our buffers
    OSStatus status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut,
                                                         flagsOut, NULL, numberFramesOut);
    if (status != noErr) return;

    // Check if EQ is enabled
    if (!atomic_load_explicit(&sParams.enabled, memory_order_relaxed)) return;

    TapContext *ctx = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    if (!ctx) return;

    // Rebuild coefficients if they changed
    int currentVersion = atomic_load_explicit(&sParams.coeffVersion, memory_order_relaxed);
    if (currentVersion != ctx->lastCoeffVersion) {
        rebuildCoefficients(ctx);
    }

    int mono = atomic_load_explicit(&sParams.mono, memory_order_relaxed);
    int loudnessMb = atomic_load_explicit(&sParams.loudnessGainMb, memory_order_relaxed);
    float loudnessGain = (loudnessMb > 0) ? powf(10.0f, (float)loudnessMb / 2000.0f) : 1.0f;
    int hasBass = atomic_load_explicit(&sParams.bassBoostStrength, memory_order_relaxed) > 0;
    // With the slider back at zero the leveler eases its gain down to 1
    // before the pass stops, so the level never steps.
    int leveling = loudnessMb > 0 || ctx->leveler.gain > 1.0001f;

    UInt32 numBuffers = bufferListInOut->mNumberBuffers;
    CMItemCount frames = *numberFramesOut;

    // Detect layout: non-interleaved has 1 channel per buffer, interleaved has all in one buffer
    BOOL nonInterleaved = (numBuffers > 1 && bufferListInOut->mBuffers[0].mNumberChannels == 1);

    if (nonInterleaved) {
        // ── Non-interleaved: each buffer = one channel ──
        int totalChans = (int)numBuffers;
        if (totalChans > MAX_CHANNELS) totalChans = MAX_CHANNELS;

        for (int ch = 0; ch < totalChans; ch++) {
            float *data = (float *)bufferListInOut->mBuffers[ch].mData;
            if (!data) continue;

            for (CMItemCount f = 0; f < frames; f++) {
                float sample = data[f];

                // Apply 5-band EQ
                for (int band = 0; band < EQ_NUM_BANDS; band++) {
                    sample = processBiquad(&ctx->coeffs[band], &ctx->delays[band][ch], sample);
                }

                // Apply bass boost shelf
                if (hasBass) {
                    sample = processBiquad(&ctx->bassCoeffs, &ctx->bassDelay[ch], sample);
                }

                data[f] = sample;
            }
        }

        if (leveling) {
            float *chans[MAX_CHANNELS] = {NULL, NULL};
            for (int ch = 0; ch < totalChans; ch++) {
                chans[ch] = (float *)bufferListInOut->mBuffers[ch].mData;
            }
            for (CMItemCount f = 0; f < frames; f++) {
                float peak = 0.0f;
                for (int ch = 0; ch < totalChans; ch++) {
                    if (!chans[ch]) continue;
                    float magnitude = fabsf(chans[ch][f]);
                    if (magnitude > peak) peak = magnitude;
                }
                float gain = levelerNext(&ctx->leveler, peak, loudnessGain);
                for (int ch = 0; ch < totalChans; ch++) {
                    if (!chans[ch]) continue;
                    chans[ch][f] = levelerClamp(chans[ch][f] * gain);
                }
            }
        }

        // Mono downmix for non-interleaved stereo
        if (mono && totalChans >= 2) {
            float *L = (float *)bufferListInOut->mBuffers[0].mData;
            float *R = (float *)bufferListInOut->mBuffers[1].mData;
            if (L && R) {
                for (CMItemCount f = 0; f < frames; f++) {
                    float avg = (L[f] + R[f]) * 0.5f;
                    L[f] = avg;
                    R[f] = avg;
                }
            }
        }
    } else {
        // ── Interleaved: all channels in one buffer ──
        for (UInt32 buf = 0; buf < numBuffers; buf++) {
            AudioBuffer *ab = &bufferListInOut->mBuffers[buf];
            float *data = (float *)ab->mData;
            if (!data) continue;

            int chansInBuf = ab->mNumberChannels;

            for (CMItemCount f = 0; f < frames; f++) {
                for (int ch = 0; ch < chansInBuf && ch < MAX_CHANNELS; ch++) {
                    float sample = data[f * chansInBuf + ch];

                    for (int band = 0; band < EQ_NUM_BANDS; band++) {
                        sample = processBiquad(&ctx->coeffs[band], &ctx->delays[band][ch], sample);
                    }

                    if (hasBass) {
                        sample = processBiquad(&ctx->bassCoeffs, &ctx->bassDelay[ch], sample);
                    }

                    data[f * chansInBuf + ch] = sample;
                }

                if (leveling) {
                    float peak = 0.0f;
                    for (int ch = 0; ch < chansInBuf; ch++) {
                        float magnitude = fabsf(data[f * chansInBuf + ch]);
                        if (magnitude > peak) peak = magnitude;
                    }
                    float gain = levelerNext(&ctx->leveler, peak, loudnessGain);
                    for (int ch = 0; ch < chansInBuf; ch++) {
                        float *sample = &data[f * chansInBuf + ch];
                        *sample = levelerClamp(*sample * gain);
                    }
                }

                // Mono downmix
                if (mono && chansInBuf >= 2) {
                    float avg = (data[f * chansInBuf] + data[f * chansInBuf + 1]) * 0.5f;
                    data[f * chansInBuf]     = avg;
                    data[f * chansInBuf + 1] = avg;
                }
            }
        }
    }
}

// ── AudioEQProcessor Objective-C implementation ──

@implementation AudioEQProcessor

+ (AudioEQProcessor *)shared {
    static AudioEQProcessor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioEQProcessor alloc] init];
    });
    return instance;
}

+ (void)setFormatLogger:(void (^)(NSString *))logger {
    sFormatLogger = [logger copy];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialise all atomic params to defaults
        atomic_store(&sParams.enabled, 0);
        atomic_store(&sParams.mono, 0);
        atomic_store(&sParams.loudnessGainMb, 0);
        atomic_store(&sParams.bassBoostStrength, 0);
        atomic_store(&sParams.coeffVersion, 0);
        for (int i = 0; i < EQ_NUM_BANDS; i++) {
            atomic_store(&sParams.bandLevels[i], 0);
        }
    }
    return self;
}

- (void)attachTapToPlayerItem:(AVPlayerItem *)item {
    if (!item) return;

    if (!atomic_load_explicit(&sParams.enabled, memory_order_relaxed)) {
        NSLog(@"[AudioEQProcessor] EQ disabled, skipping tap attach");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JustAudioDiag" object:nil userInfo:@{@"message": @"[AudioEQProcessor] EQ disabled, skipping tap attach"}];
        return;
    }

    // Build tap callbacks struct
    MTAudioProcessingTapCallbacks callbacks;
    callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
    callbacks.clientInfo = (__bridge void *)self;
    callbacks.init = tapInit;
    callbacks.finalize = tapFinalize;
    callbacks.prepare = tapPrepare;
    callbacks.unprepare = tapUnprepare;
    callbacks.process = tapProcess;

    MTAudioProcessingTapRef tap = NULL;
    OSStatus status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks,
                                                  kMTAudioProcessingTapCreationFlag_PostEffects,
                                                  &tap);
    if (status != noErr || !tap) {
        NSLog(@"[AudioEQProcessor] Failed to create tap: %d", (int)status);
        return;
    }

    // We need to wait for tracks to be available before attaching the tap.
    // For local files this is immediate; for streaming it may be async.
    AVAsset *asset = item.asset;
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus trackStatus = [asset statusOfValueForKey:@"tracks" error:&error];
        if (trackStatus != AVKeyValueStatusLoaded) {
            NSLog(@"[AudioEQProcessor] Tracks not loaded: %@", error);
            CFRelease(tap);
            return;
        }

        NSArray<AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count == 0) {
            NSLog(@"[AudioEQProcessor] No audio tracks found");
            CFRelease(tap);
            return;
        }

        // Create audio mix with tap on every audio track
        NSMutableArray<AVMutableAudioMixInputParameters *> *inputParams = [NSMutableArray array];
        for (AVAssetTrack *track in audioTracks) {
            AVMutableAudioMixInputParameters *params =
                [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
            params.audioTapProcessor = tap;
            [inputParams addObject:params];
        }

        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = inputParams;

        // Must set audioMix on main thread (AVPlayerItem is not thread-safe)
        dispatch_async(dispatch_get_main_queue(), ^{
            item.audioMix = audioMix;
        });

        CFRelease(tap);
    }];
}

- (void)setEnabled:(BOOL)enabled {
    atomic_store_explicit(&sParams.enabled, enabled ? 1 : 0, memory_order_relaxed);
}

- (void)setBandLevel:(int)level forBand:(int)band {
    if (band < 0 || band >= EQ_NUM_BANDS) return;
    atomic_store_explicit(&sParams.bandLevels[band], level, memory_order_relaxed);
    atomic_fetch_add_explicit(&sParams.coeffVersion, 1, memory_order_release);
}

- (void)setBassBoostStrength:(int)strength {
    atomic_store_explicit(&sParams.bassBoostStrength, strength, memory_order_relaxed);
    atomic_fetch_add_explicit(&sParams.coeffVersion, 1, memory_order_release);
}

- (void)setLoudnessGain:(int)gainMb {
    atomic_store_explicit(&sParams.loudnessGainMb, gainMb, memory_order_relaxed);
}

- (void)setMonoEnabled:(BOOL)enabled {
    atomic_store_explicit(&sParams.mono, enabled ? 1 : 0, memory_order_relaxed);
}

@end
