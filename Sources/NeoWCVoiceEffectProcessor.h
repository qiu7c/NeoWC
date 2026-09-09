#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NeoWCRealtimeVoiceEffect) {
    NeoWCRealtimeVoiceEffectOff = 0,
    NeoWCRealtimeVoiceEffectBright = 1,
    NeoWCRealtimeVoiceEffectDeep = 2,
    NeoWCRealtimeVoiceEffectRobot = 3,
    NeoWCRealtimeVoiceEffectElectronic = 4,
};

/// Atomically selects the effect used by subsequent microphone callbacks.
FOUNDATION_EXPORT void NeoWCVoiceEffectSetPreset(NeoWCRealtimeVoiceEffect effect);

/// Returns the currently active real-time effect.
FOUNDATION_EXPORT NeoWCRealtimeVoiceEffect NeoWCVoiceEffectPreset(void);

/// Returns the localized display name for an effect.
FOUNDATION_EXPORT NSString *NeoWCVoiceEffectName(NeoWCRealtimeVoiceEffect effect);

/// Processes one writable microphone PCM buffer in place.
/// Supports interleaved/non-interleaved signed 16-bit and float32 linear PCM.
/// The audio callback may call this function directly: it performs no allocation,
/// locking, Objective-C messaging, file access, or settings reads while enabled.
FOUNDATION_EXPORT void NeoWCVoiceEffectProcess(AudioStreamBasicDescription format,
                                               UInt32 frames,
                                               AudioBufferList * _Nullable buffers);

/// Clears delay lines and oscillator state at call boundaries.
FOUNDATION_EXPORT void NeoWCVoiceEffectReset(void);

NS_ASSUME_NONNULL_END
