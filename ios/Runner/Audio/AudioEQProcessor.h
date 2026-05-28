#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Singleton that owns EQ DSP state and attaches MTAudioProcessingTap
/// to AVPlayerItems for real-time audio equalisation on iOS.
@interface AbsorbAudioEQProcessor : NSObject

@property (class, readonly) AbsorbAudioEQProcessor *shared;

/// Attach a processing tap to the given player item. Asset tracks load
/// asynchronously; `shouldStillAttach` is invoked just before the audio mix
/// is assigned so the caller can bail out if the item has been replaced.
- (void)attachTapToPlayerItem:(AVPlayerItem *)item
            shouldStillAttach:(BOOL (^_Nullable)(void))shouldStillAttach;

/// Attach the tap synchronously (asset tracks must already be loaded). Call
/// before playback starts - a tap installed after is silently ignored.
- (void)attachTapSyncToPlayerItem:(AVPlayerItem *)item;

/// Detach the tap by clearing the player item's audioMix.
- (void)detachFromPlayerItem:(AVPlayerItem *)item;

/// Master EQ enable/disable.
- (void)setEnabled:(BOOL)enabled;

/// Set a single band level in millibels (e.g. -1500 to +1500 for +/-15 dB).
/// @param band  Band index 0-4.
/// @param level Level in millibels.
- (void)setBandLevel:(int)level forBand:(int)band;

/// Set bass boost strength (0-1000).
- (void)setBassBoostStrength:(int)strength;

/// Set loudness gain in millibels (added on top of output).
- (void)setLoudnessGain:(int)gainMb;

/// Enable mono downmix.
- (void)setMonoEnabled:(BOOL)enabled;

/// Sets a callback that gets each `[EQDiag]` line emitted from
/// tapPrepare so callers can route format info into their own logger.
+ (void)setFormatLogger:(nullable void (^)(NSString *line))logger;

@end

NS_ASSUME_NONNULL_END
