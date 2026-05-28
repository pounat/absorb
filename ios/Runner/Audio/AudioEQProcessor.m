#import "AudioEQProcessor.h"
#import <MediaToolbox/MediaToolbox.h>
#import <Accelerate/Accelerate.h>
#import <stdatomic.h>
#import <math.h>

#define EQ_NUM_BANDS    5
#define MAX_CHANNELS    2

static const float kBandFrequencies[EQ_NUM_BANDS] = {60.0f, 230.0f, 910.0f, 3600.0f, 14000.0f};
static const float kDefaultQ = 1.4f;

typedef struct {
    float b0, b1, b2, a1, a2;
} BiquadCoeffs;

typedef struct {
    float x1, x2;
    float y1, y2;
} BiquadDelay;

typedef struct {
    _Atomic(int)  enabled;
    _Atomic(int)  mono;
    _Atomic(int)  loudnessGainMb;
    _Atomic(int)  bassBoostStrength;
    _Atomic(int)  bandLevels[EQ_NUM_BANDS];
    _Atomic(int)  coeffVersion;
} EQParams;

typedef struct {
    BiquadDelay delays[EQ_NUM_BANDS][MAX_CHANNELS];
    BiquadDelay bassDelay[MAX_CHANNELS];
    BiquadCoeffs coeffs[EQ_NUM_BANDS];
    BiquadCoeffs bassCoeffs;
    float sampleRate;
    int numChannels;
    int lastCoeffVersion;
} TapContext;

static EQParams sParams;

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

static inline float processBiquad(BiquadCoeffs *c, BiquadDelay *d, float x) {
    float y = c->b0 * x + c->b1 * d->x1 + c->b2 * d->x2
                         - c->a1 * d->y1 - c->a2 * d->y2;
    d->x2 = d->x1;
    d->x1 = x;
    d->y2 = d->y1;
    d->y1 = y;
    return y;
}

static void rebuildCoefficients(TapContext *ctx) {
    float Fs = ctx->sampleRate;
    // Clamp band frequencies below Nyquist with 5% headroom. A peaking
    // biquad at f0 >= Fs/2 puts the filter poles outside the unit circle,
    // the filter blows up, samples turn into NaN, and the output goes
    // silent. Low-bitrate AAC m4b decodes to 22050Hz so the 14kHz band
    // tripped this without the clamp.
    float maxBandHz = (Fs * 0.5f) * 0.95f;
    for (int i = 0; i < EQ_NUM_BANDS; i++) {
        float dBGain = (float)atomic_load_explicit(&sParams.bandLevels[i], memory_order_relaxed) / 100.0f;
        float bandHz = kBandFrequencies[i];
        if (bandHz >= maxBandHz) {
            BiquadCoeffs unity = {1.0f, 0.0f, 0.0f, 0.0f, 0.0f};
            ctx->coeffs[i] = unity;
        } else {
            ctx->coeffs[i] = peakingEQ(bandHz, dBGain, kDefaultQ, Fs);
        }
    }

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

static void tapInit(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
    TapContext *ctx = (TapContext *)calloc(1, sizeof(TapContext));
    *tapStorageOut = ctx;
}

static void tapFinalize(MTAudioProcessingTapRef tap) {
    TapContext *ctx = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    if (ctx) free(ctx);
}

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

    memset(ctx->delays, 0, sizeof(ctx->delays));
    memset(ctx->bassDelay, 0, sizeof(ctx->bassDelay));

    rebuildCoefficients(ctx);

    // Dump the post-decode PCM format so "tap enabled produces silence"
    // reports can be correlated to specific format fingerprints (e.g. low
    // bitrate AAC at 22050Hz mono).
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
}

static void tapProcess(MTAudioProcessingTapRef tap,
                       CMItemCount numberFrames,
                       MTAudioProcessingTapFlags flags,
                       AudioBufferList *bufferListInOut,
                       CMItemCount *numberFramesOut,
                       MTAudioProcessingTapFlags *flagsOut) {
    OSStatus status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut,
                                                         flagsOut, NULL, numberFramesOut);
    if (status != noErr) return;

    int bandsOn = atomic_load_explicit(&sParams.enabled, memory_order_relaxed);
    int mono = atomic_load_explicit(&sParams.mono, memory_order_relaxed);
    int loudnessMb = atomic_load_explicit(&sParams.loudnessGainMb, memory_order_relaxed);
    int hasBass = atomic_load_explicit(&sParams.bassBoostStrength, memory_order_relaxed) > 0;

    // Bass / loudness / mono apply independently of the band-EQ master switch,
    // so process whenever any of them is active - not only when bands are on.
    if (!bandsOn && !mono && loudnessMb <= 0 && !hasBass) return;

    TapContext *ctx = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    if (!ctx) return;

    int currentVersion = atomic_load_explicit(&sParams.coeffVersion, memory_order_relaxed);
    if (currentVersion != ctx->lastCoeffVersion) {
        rebuildCoefficients(ctx);
    }

    float loudnessGain = (loudnessMb > 0) ? powf(10.0f, (float)loudnessMb / 2000.0f) : 1.0f;

    UInt32 numBuffers = bufferListInOut->mNumberBuffers;
    CMItemCount frames = *numberFramesOut;

    BOOL nonInterleaved = (numBuffers > 1 && bufferListInOut->mBuffers[0].mNumberChannels == 1);

    if (nonInterleaved) {
        int totalChans = (int)numBuffers;
        if (totalChans > MAX_CHANNELS) totalChans = MAX_CHANNELS;

        for (int ch = 0; ch < totalChans; ch++) {
            float *data = (float *)bufferListInOut->mBuffers[ch].mData;
            if (!data) continue;

            for (CMItemCount f = 0; f < frames; f++) {
                float sample = data[f];

                if (bandsOn) {
                    for (int band = 0; band < EQ_NUM_BANDS; band++) {
                        sample = processBiquad(&ctx->coeffs[band], &ctx->delays[band][ch], sample);
                    }
                }

                if (hasBass) {
                    sample = processBiquad(&ctx->bassCoeffs, &ctx->bassDelay[ch], sample);
                }

                if (loudnessMb > 0) {
                    sample *= loudnessGain;
                }

                data[f] = sample;
            }
        }

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
        for (UInt32 buf = 0; buf < numBuffers; buf++) {
            AudioBuffer *ab = &bufferListInOut->mBuffers[buf];
            float *data = (float *)ab->mData;
            if (!data) continue;

            int chansInBuf = ab->mNumberChannels;

            for (CMItemCount f = 0; f < frames; f++) {
                for (int ch = 0; ch < chansInBuf && ch < MAX_CHANNELS; ch++) {
                    float sample = data[f * chansInBuf + ch];

                    if (bandsOn) {
                        for (int band = 0; band < EQ_NUM_BANDS; band++) {
                            sample = processBiquad(&ctx->coeffs[band], &ctx->delays[band][ch], sample);
                        }
                    }

                    if (hasBass) {
                        sample = processBiquad(&ctx->bassCoeffs, &ctx->bassDelay[ch], sample);
                    }

                    if (loudnessMb > 0) {
                        sample *= loudnessGain;
                    }

                    data[f * chansInBuf + ch] = sample;
                }

                if (mono && chansInBuf >= 2) {
                    float avg = (data[f * chansInBuf] + data[f * chansInBuf + 1]) * 0.5f;
                    data[f * chansInBuf]     = avg;
                    data[f * chansInBuf + 1] = avg;
                }
            }
        }
    }
}

@implementation AbsorbAudioEQProcessor

+ (AbsorbAudioEQProcessor *)shared {
    static AbsorbAudioEQProcessor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AbsorbAudioEQProcessor alloc] init];
    });
    return instance;
}

+ (void)setFormatLogger:(void (^)(NSString *))logger {
    sFormatLogger = [logger copy];
}

- (instancetype)init {
    self = [super init];
    if (self) {
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

- (void)attachTapToPlayerItem:(AVPlayerItem *)item
            shouldStillAttach:(BOOL (^)(void))shouldStillAttach {
    if (!item) return;

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

        NSMutableArray<AVMutableAudioMixInputParameters *> *inputParams = [NSMutableArray array];
        for (AVAssetTrack *track in audioTracks) {
            AVMutableAudioMixInputParameters *params =
                [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
            params.audioTapProcessor = tap;
            [inputParams addObject:params];
        }

        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = inputParams;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (shouldStillAttach && !shouldStillAttach()) {
                NSLog(@"[AudioEQProcessor] Item replaced before tap attach, skipping");
                CFRelease(tap);
                return;
            }
            item.audioMix = audioMix;
            CFRelease(tap);
        });
    }];
}

- (void)attachTapSyncToPlayerItem:(AVPlayerItem *)item {
    if (!item) return;

    AVAsset *asset = item.asset;
    NSArray<AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count == 0) {
        NSLog(@"[AudioEQProcessor] sync attach: no audio tracks (asset not preloaded?)");
        return;
    }

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
        NSLog(@"[AudioEQProcessor] sync attach: failed to create tap: %d", (int)status);
        return;
    }

    NSMutableArray<AVMutableAudioMixInputParameters *> *inputParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *params =
            [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        params.audioTapProcessor = tap;
        [inputParams addObject:params];
    }

    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = inputParams;
    item.audioMix = audioMix;
    CFRelease(tap);
}

- (void)detachFromPlayerItem:(AVPlayerItem *)item {
    if (!item) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        item.audioMix = nil;
    });
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
