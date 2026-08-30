#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const NeoWCEncryptedMessageEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCMediaEncryptionEnabledKey;
FOUNDATION_EXPORT NSString *const NeoWCEncryptedTextPlaceholder;

/// Builds a normal WeChat text message whose visible fallback is `【密文】`.
FOUNDATION_EXPORT NSString * _Nullable NeoWCEncryptedTextWireString(NSString *plainText,
                                                                    NSError **error);
FOUNDATION_EXPORT BOOL NeoWCIsEncryptedTextWireString(NSString *wireText);
FOUNDATION_EXPORT NSString * _Nullable NeoWCDecryptTextWireString(NSString *wireText,
                                                                  NSError **error);

typedef NS_ENUM(uint8_t, NeoWCWXCFileType) {
    NeoWCWXCFileTypeImage = 1,
    NeoWCWXCFileTypeLivePhotoImage = 2,
    NeoWCWXCFileTypeVideo = 3,
};

/// WeChatX-compatible WXCENC01 media container functions.
FOUNDATION_EXPORT BOOL NeoWCWXCInspectFile(NSString *path,
                                           uint8_t * _Nullable typeOut,
                                           NSString * _Nullable * _Nullable metadataOut);
FOUNDATION_EXPORT BOOL NeoWCWXCEncryptFile(NSString *inputPath,
                                           NSString *outputPath,
                                           NeoWCWXCFileType type,
                                           NSString *metadata,
                                           NSError **error);
FOUNDATION_EXPORT BOOL NeoWCWXCDecryptFile(NSString *inputPath,
                                           NSString *outputPath,
                                           uint8_t * _Nullable typeOut,
                                           NSString * _Nullable * _Nullable metadataOut,
                                           NSError **error);

NS_ASSUME_NONNULL_END
