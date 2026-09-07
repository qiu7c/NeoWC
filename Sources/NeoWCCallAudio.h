#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Installs the guarded WeChat VoIP lifecycle hooks and AudioUnit PCM adapters.
/// Safe to call repeatedly; unsupported WeChat methods or AudioUnit symbols are skipped.
FOUNDATION_EXPORT void NeoWCCallAudioInstallHooks(void);

/// Marks the WeChat audio device as started after `VoipUIManager`
/// `audioDeviceStartedSuccess:` has invoked its original implementation.
/// Must be called on the main thread; repeated notifications are idempotent.
FOUNDATION_EXPORT void NeoWCCallAudioNotifyAudioDeviceStarted(void);

NS_ASSUME_NONNULL_END
