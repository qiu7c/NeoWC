#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL NeoWCEncodeAudioFileToSilk(NSString *sourcePath,
                                                   NSString *destinationPath,
                                                   NSUInteger * _Nullable durationMilliseconds,
                                                   NSError **error);

NS_ASSUME_NONNULL_END
