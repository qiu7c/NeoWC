#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Installs the guarded WeChat VoIP lifecycle hooks and AudioUnit PCM adapters.
/// Safe to call repeatedly; unsupported WeChat methods or AudioUnit symbols are skipped.
FOUNDATION_EXPORT void NeoWCCallAudioInstallHooks(void);

NS_ASSUME_NONNULL_END
