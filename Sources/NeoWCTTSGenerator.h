#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Generates Mandarin speech with the system speech synthesizer and writes it to
/// a temporary Core Audio file. The completion block runs on the main thread.
/// The caller owns removal of a successful output URL after copying or consuming it.
FOUNDATION_EXPORT void NeoWCGenerateLocalSpeech(NSString *text,
                                                void (^completion)(NSURL * _Nullable outputURL,
                                                                   NSError * _Nullable error));

NS_ASSUME_NONNULL_END
