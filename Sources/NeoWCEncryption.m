#import "NeoWCEncryption.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/Security.h>

NSString *const NeoWCEncryptedMessageEnabledKey = @"com.qiu7c.neowc.chat.encrypted-message";
NSString *const NeoWCMediaEncryptionEnabledKey = @"com.qiu7c.neowc.chat.encrypted-message.media";
NSString *const NeoWCEncryptedTextPlaceholder = @"【密文】";

static NSString *const NeoWCEncryptionErrorDomain = @"com.qiu7c.neowc.encryption";
static const uint32_t NeoWCPBKDFRounds = 120000;
static const NSUInteger NeoWCTextMaximumPlaintextBytes = 600;
static const NSUInteger NeoWCTextFixedHeaderLength = 52;
static const NSUInteger NeoWCWXCFixedHeaderLength = 56;
static const NSUInteger NeoWCHMACLength = CC_SHA256_DIGEST_LENGTH;
static const NSUInteger NeoWCStreamChunkLength = 0x40000;

// Shared by every NeoWC installation. This provides plugin interoperability,
// not secrecy against somebody who reverse engineers the plugin binary.
static NSString *const NeoWCTextPassword = @"kQ5m4H2cZ9sV7rN1xL8uF3aD6pT0jWbE";
// Exact fixed password used by WeChatX 2.1-9. Unlike NeoWC text packets, the
// WXC container passes this mixed-case Base64 string to PBKDF2 unchanged.
static NSString *const NeoWCWXCPassword = @"tEXdNmORrxj6D1aFznvnIBKrWcS+cAbs1WmSP06h8xo=";

static void NeoWCSetEncryptionError(NSError **error, NSInteger code, NSString *description) {
    if (!error) return;
    *error = [NSError errorWithDomain:NeoWCEncryptionErrorDomain
                                 code:code
                             userInfo:@{NSLocalizedDescriptionKey: description ?: @"加密处理失败"}];
}

static void NeoWCWriteUInt16BE(uint8_t *bytes, uint16_t value) {
    bytes[0] = (uint8_t)(value >> 8);
    bytes[1] = (uint8_t)value;
}

static void NeoWCWriteUInt32BE(uint8_t *bytes, uint32_t value) {
    bytes[0] = (uint8_t)(value >> 24);
    bytes[1] = (uint8_t)(value >> 16);
    bytes[2] = (uint8_t)(value >> 8);
    bytes[3] = (uint8_t)value;
}

static void NeoWCWriteUInt64BE(uint8_t *bytes, uint64_t value) {
    for (NSUInteger index = 0; index < 8; index++) bytes[index] = (uint8_t)(value >> (56 - 8 * index));
}

static uint16_t NeoWCReadUInt16BE(const uint8_t *bytes) {
    return (uint16_t)(((uint16_t)bytes[0] << 8) | bytes[1]);
}

static uint32_t NeoWCReadUInt32BE(const uint8_t *bytes) {
    return ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) |
           ((uint32_t)bytes[2] << 8) | bytes[3];
}

static uint64_t NeoWCReadUInt64BE(const uint8_t *bytes) {
    uint64_t value = 0;
    for (NSUInteger index = 0; index < 8; index++) value = (value << 8) | bytes[index];
    return value;
}

static BOOL NeoWCRandomBytes(uint8_t *bytes, NSUInteger length, NSError **error) {
    if (SecRandomCopyBytes(kSecRandomDefault, length, bytes) == errSecSuccess) return YES;
    NeoWCSetEncryptionError(error, 2, @"无法生成安全随机数");
    return NO;
}

static BOOL NeoWCDeriveKeys(NSString *password,
                            const uint8_t salt[16],
                            uint32_t rounds,
                            BOOL lowercasePassword,
                            uint8_t output[64],
                            NSError **error) {
    NSString *normalized = lowercasePassword ? password.lowercaseString : password;
    NSData *passwordData = [normalized dataUsingEncoding:NSUTF8StringEncoding];
    if (!passwordData || rounds < 10000 || rounds > 2000000) {
        NeoWCSetEncryptionError(error, 3, @"密钥参数无效");
        return NO;
    }
    int status = CCKeyDerivationPBKDF(kCCPBKDF2,
                                      passwordData.bytes, passwordData.length,
                                      salt, 16,
                                      kCCPRFHmacAlgSHA256, rounds,
                                      output, 64);
    if (status == kCCSuccess) return YES;
    NeoWCSetEncryptionError(error, 3, @"密钥派生失败");
    return NO;
}

static NSData *NeoWCAESCryptData(NSData *input,
                                 CCOperation operation,
                                 const uint8_t key[32],
                                 const uint8_t iv[16],
                                 NSError **error) {
    size_t capacity = input.length + kCCBlockSizeAES128;
    NSMutableData *output = [NSMutableData dataWithLength:capacity];
    size_t written = 0;
    CCCryptorStatus status = CCCrypt(operation, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                     key, 32, iv,
                                     input.bytes, input.length,
                                     output.mutableBytes, output.length, &written);
    if (status != kCCSuccess) {
        NeoWCSetEncryptionError(error, 4, @"AES 处理失败");
        return nil;
    }
    output.length = written;
    return output;
}

static NSData *NeoWCHMAC(NSData *data, const uint8_t key[32]) {
    uint8_t digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmac(kCCHmacAlgSHA256, key, 32, data.bytes, data.length, digest);
    return [NSData dataWithBytes:digest length:sizeof(digest)];
}

static BOOL NeoWCConstantTimeEqual(NSData *left, NSData *right) {
    if (left.length != right.length) return NO;
    const uint8_t *a = left.bytes;
    const uint8_t *b = right.bytes;
    uint8_t difference = 0;
    for (NSUInteger index = 0; index < left.length; index++) difference |= a[index] ^ b[index];
    return difference == 0;
}

static NSString *NeoWCBase64URLString(NSData *data) {
    NSString *value = [data base64EncodedStringWithOptions:0];
    value = [value stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    value = [value stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [value stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

static NSData *NeoWCDataFromBase64URLString(NSString *value) {
    NSString *base64 = [[value stringByReplacingOccurrencesOfString:@"-" withString:@"+"]
        stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    NSUInteger padding = (4 - base64.length % 4) % 4;
    if (padding) base64 = [base64 stringByPaddingToLength:base64.length + padding withString:@"=" startingAtIndex:0];
    return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
}

NSString *NeoWCEncryptedTextWireString(NSString *plainText, NSError **error) {
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    if (plainData.length == 0) {
        NeoWCSetEncryptionError(error, 10, @"没有可加密的文字");
        return nil;
    }
    if (plainData.length > NeoWCTextMaximumPlaintextBytes) {
        NeoWCSetEncryptionError(error, 10, @"密文消息最多支持 600 字节 UTF-8 内容");
        return nil;
    }

    uint8_t salt[16] = {0}, iv[16] = {0}, keys[64] = {0};
    if (!NeoWCRandomBytes(salt, sizeof(salt), error) ||
        !NeoWCRandomBytes(iv, sizeof(iv), error) ||
        !NeoWCDeriveKeys(NeoWCTextPassword, salt, NeoWCPBKDFRounds, YES, keys, error)) return nil;
    NSData *ciphertext = NeoWCAESCryptData(plainData, kCCEncrypt, keys, iv, error);
    if (!ciphertext) return nil;

    NSMutableData *packet = [NSMutableData dataWithLength:NeoWCTextFixedHeaderLength];
    uint8_t *header = packet.mutableBytes;
    memcpy(header, "NWCENC01", 8);
    header[8] = 1;
    header[9] = 1; // UTF-8 text.
    NeoWCWriteUInt32BE(header + 12, NeoWCPBKDFRounds);
    NeoWCWriteUInt32BE(header + 16, (uint32_t)plainData.length);
    memcpy(header + 20, salt, 16);
    memcpy(header + 36, iv, 16);
    [packet appendData:ciphertext];
    [packet appendData:NeoWCHMAC(packet, keys + 32)];

    NSString *encoded = NeoWCBase64URLString(packet);
    return encoded ? [NeoWCEncryptedTextPlaceholder stringByAppendingString:encoded] : nil;
}

BOOL NeoWCIsEncryptedTextWireString(NSString *wireText) {
    if (![wireText isKindOfClass:NSString.class] || ![wireText hasPrefix:NeoWCEncryptedTextPlaceholder]) return NO;
    NSString *encoded = [wireText substringFromIndex:NeoWCEncryptedTextPlaceholder.length];
    if (encoded.length == 0) return NO;
    NSData *packet = NeoWCDataFromBase64URLString(encoded);
    if (packet.length < NeoWCTextFixedHeaderLength + 16 + NeoWCHMACLength) return NO;
    const uint8_t *bytes = packet.bytes;
    return memcmp(bytes, "NWCENC01", 8) == 0 && bytes[8] == 1 && bytes[9] == 1;
}

NSString *NeoWCDecryptTextWireString(NSString *wireText, NSError **error) {
    if (!NeoWCIsEncryptedTextWireString(wireText)) return nil;
    NSString *encoded = [wireText substringFromIndex:NeoWCEncryptedTextPlaceholder.length];
    NSData *packet = NeoWCDataFromBase64URLString(encoded);
    if (packet.length < NeoWCTextFixedHeaderLength + 16 + NeoWCHMACLength) {
        NeoWCSetEncryptionError(error, 11, @"密文消息已截断");
        return nil;
    }
    const uint8_t *bytes = packet.bytes;
    if (memcmp(bytes, "NWCENC01", 8) != 0 || bytes[8] != 1 || bytes[9] != 1) {
        NeoWCSetEncryptionError(error, 11, @"不是受支持的 NeoWC 密文");
        return nil;
    }
    uint32_t rounds = NeoWCReadUInt32BE(bytes + 12);
    uint32_t expectedLength = NeoWCReadUInt32BE(bytes + 16);
    if (expectedLength == 0 || expectedLength > NeoWCTextMaximumPlaintextBytes) {
        NeoWCSetEncryptionError(error, 11, @"密文长度无效");
        return nil;
    }
    uint8_t keys[64] = {0};
    if (!NeoWCDeriveKeys(NeoWCTextPassword, bytes + 20, rounds, YES, keys, error)) return nil;
    NSData *authenticated = [packet subdataWithRange:NSMakeRange(0, packet.length - NeoWCHMACLength)];
    NSData *storedTag = [packet subdataWithRange:NSMakeRange(packet.length - NeoWCHMACLength, NeoWCHMACLength)];
    if (!NeoWCConstantTimeEqual(NeoWCHMAC(authenticated, keys + 32), storedTag)) {
        NeoWCSetEncryptionError(error, 12, @"密文校验失败");
        return nil;
    }
    NSData *ciphertext = [packet subdataWithRange:NSMakeRange(NeoWCTextFixedHeaderLength,
                                                              packet.length - NeoWCTextFixedHeaderLength - NeoWCHMACLength)];
    NSData *plainData = NeoWCAESCryptData(ciphertext, kCCDecrypt, keys, bytes + 36, error);
    if (plainData.length != expectedLength) {
        NeoWCSetEncryptionError(error, 12, @"解密后的长度不一致");
        return nil;
    }
    NSString *plainText = [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
    if (!plainText) NeoWCSetEncryptionError(error, 12, @"解密结果不是 UTF-8 文本");
    return plainText;
}

static BOOL NeoWCWriteFileData(NSFileHandle *handle, NSData *data, NSError **error) {
    @try {
        [handle writeData:data];
        return YES;
    } @catch (__unused NSException *exception) {
        NeoWCSetEncryptionError(error, 21, @"写入加密文件失败");
        return NO;
    }
}

static NSData *NeoWCReadFileData(NSFileHandle *handle, NSUInteger length, NSError **error) {
    @try {
        return [handle readDataOfLength:length];
    } @catch (__unused NSException *exception) {
        NeoWCSetEncryptionError(error, 21, @"读取加密文件失败");
        return nil;
    }
}

static BOOL NeoWCPrepareOutputPath(NSString *path, NSError **error) {
    NSString *directory = path.stringByDeletingLastPathComponent;
    if (directory.length > 0 &&
        ![NSFileManager.defaultManager createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES attributes:nil error:error]) return NO;
    [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    if ([NSFileManager.defaultManager createFileAtPath:path contents:nil attributes:nil]) return YES;
    NeoWCSetEncryptionError(error, 21, @"无法创建输出文件");
    return NO;
}

BOOL NeoWCWXCInspectFile(NSString *path, uint8_t *typeOut, NSString **metadataOut) {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!handle) return NO;
    NSData *headerData = NeoWCReadFileData(handle, NeoWCWXCFixedHeaderLength, nil);
    const uint8_t *header = headerData.bytes;
    if (headerData.length != NeoWCWXCFixedHeaderLength || memcmp(header, "WXCENC01", 8) != 0 ||
        header[8] != 1 || header[9] < 1) {
        [handle closeFile];
        return NO;
    }
    uint16_t metadataLength = NeoWCReadUInt16BE(header + 10);
    uint32_t rounds = NeoWCReadUInt32BE(header + 12);
    if (metadataLength > 64 || rounds < 10000 || rounds > 2000000) {
        [handle closeFile];
        return NO;
    }
    NSData *metadataData = NeoWCReadFileData(handle, metadataLength, nil);
    [handle closeFile];
    NSString *metadata = [[NSString alloc] initWithData:metadataData encoding:NSUTF8StringEncoding];
    if (metadataData.length != metadataLength || (metadataLength > 0 && !metadata)) return NO;
    if (typeOut) *typeOut = header[9];
    if (metadataOut) *metadataOut = metadata ?: @"";
    return YES;
}

BOOL NeoWCWXCEncryptFile(NSString *inputPath,
                         NSString *outputPath,
                         NeoWCWXCFileType type,
                         NSString *metadata,
                         NSError **error) {
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:inputPath error:error];
    uint64_t inputSize = [attributes[NSFileSize] unsignedLongLongValue];
    NSData *metadataData = [metadata.lowercaseString dataUsingEncoding:NSUTF8StringEncoding];
    if (!attributes || inputSize == 0 || type < NeoWCWXCFileTypeAuxiliaryImage || type > NeoWCWXCFileTypeVideo ||
        metadataData.length > 64) {
        NeoWCSetEncryptionError(error, 20, @"媒体加密参数无效");
        return NO;
    }

    uint8_t salt[16] = {0}, iv[16] = {0}, keys[64] = {0};
    if (!NeoWCRandomBytes(salt, 16, error) || !NeoWCRandomBytes(iv, 16, error) ||
        !NeoWCDeriveKeys(NeoWCWXCPassword, salt, NeoWCPBKDFRounds, NO, keys, error)) return NO;
    NSMutableData *headerData = [NSMutableData dataWithLength:NeoWCWXCFixedHeaderLength];
    uint8_t *header = headerData.mutableBytes;
    memcpy(header, "WXCENC01", 8);
    header[8] = 1;
    header[9] = type;
    NeoWCWriteUInt16BE(header + 10, (uint16_t)metadataData.length);
    NeoWCWriteUInt32BE(header + 12, NeoWCPBKDFRounds);
    NeoWCWriteUInt64BE(header + 16, inputSize);
    memcpy(header + 24, salt, 16);
    memcpy(header + 40, iv, 16);

    NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:inputPath];
    if (!input || !NeoWCPrepareOutputPath(outputPath, error)) return NO;
    NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:outputPath];
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus cryptStatus = CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                                   keys, 32, iv, &cryptor);
    if (!output || cryptStatus != kCCSuccess) {
        [input closeFile];
        [output closeFile];
        [NSFileManager.defaultManager removeItemAtPath:outputPath error:nil];
        NeoWCSetEncryptionError(error, 22, @"无法初始化媒体加密器");
        return NO;
    }

    CCHmacContext hmac;
    CCHmacInit(&hmac, kCCHmacAlgSHA256, keys + 32, 32);
    CCHmacUpdate(&hmac, headerData.bytes, headerData.length);
    CCHmacUpdate(&hmac, metadataData.bytes, metadataData.length);
    BOOL success = NeoWCWriteFileData(output, headerData, error) && NeoWCWriteFileData(output, metadataData, error);
    while (success) {
        NSData *chunk = NeoWCReadFileData(input, NeoWCStreamChunkLength, error);
        if (!chunk) { success = NO; break; }
        if (chunk.length == 0) break;
        size_t capacity = CCCryptorGetOutputLength(cryptor, chunk.length, false);
        NSMutableData *encrypted = [NSMutableData dataWithLength:capacity];
        size_t written = 0;
        cryptStatus = CCCryptorUpdate(cryptor, chunk.bytes, chunk.length,
                                      encrypted.mutableBytes, encrypted.length, &written);
        if (cryptStatus != kCCSuccess) { success = NO; break; }
        encrypted.length = written;
        if (written) {
            CCHmacUpdate(&hmac, encrypted.bytes, encrypted.length);
            success = NeoWCWriteFileData(output, encrypted, error);
        }
    }
    if (success) {
        NSMutableData *finalData = [NSMutableData dataWithLength:kCCBlockSizeAES128];
        size_t finalLength = 0;
        cryptStatus = CCCryptorFinal(cryptor, finalData.mutableBytes, finalData.length, &finalLength);
        finalData.length = finalLength;
        if (cryptStatus != kCCSuccess) success = NO;
        if (success && finalLength) {
            CCHmacUpdate(&hmac, finalData.bytes, finalData.length);
            success = NeoWCWriteFileData(output, finalData, error);
        }
        uint8_t tag[CC_SHA256_DIGEST_LENGTH] = {0};
        CCHmacFinal(&hmac, tag);
        if (success) success = NeoWCWriteFileData(output, [NSData dataWithBytes:tag length:sizeof(tag)], error);
    }
    CCCryptorRelease(cryptor);
    [input closeFile];
    [output closeFile];
    if (!success) {
        [NSFileManager.defaultManager removeItemAtPath:outputPath error:nil];
        if (error && !*error) NeoWCSetEncryptionError(error, 22, @"媒体加密失败");
    }
    return success;
}

static BOOL NeoWCWXCReadHeader(NSFileHandle *input,
                               NSMutableData **headerAndMetadataOut,
                               uint8_t *typeOut,
                               uint32_t *roundsOut,
                               uint64_t *plainSizeOut,
                               NSString **metadataOut,
                               NSError **error) {
    NSData *headerData = NeoWCReadFileData(input, NeoWCWXCFixedHeaderLength, error);
    const uint8_t *header = headerData.bytes;
    if (headerData.length != NeoWCWXCFixedHeaderLength || memcmp(header, "WXCENC01", 8) != 0 ||
        header[8] != 1 || header[9] < 1) {
        NeoWCSetEncryptionError(error, 23, @"不是受支持的 WXCENC01 文件");
        return NO;
    }
    uint16_t metadataLength = NeoWCReadUInt16BE(header + 10);
    uint32_t rounds = NeoWCReadUInt32BE(header + 12);
    uint64_t plainSize = NeoWCReadUInt64BE(header + 16);
    if (metadataLength > 64 || rounds < 10000 || rounds > 2000000 || plainSize == 0) {
        NeoWCSetEncryptionError(error, 23, @"WXCENC01 文件头无效");
        return NO;
    }
    NSData *metadataData = NeoWCReadFileData(input, metadataLength, error);
    NSString *metadata = [[NSString alloc] initWithData:metadataData encoding:NSUTF8StringEncoding];
    if (metadataData.length != metadataLength || (metadataLength && !metadata)) {
        NeoWCSetEncryptionError(error, 23, @"WXCENC01 元数据无效");
        return NO;
    }
    NSMutableData *authenticatedHeader = [headerData mutableCopy];
    [authenticatedHeader appendData:metadataData];
    if (headerAndMetadataOut) *headerAndMetadataOut = authenticatedHeader;
    if (typeOut) *typeOut = header[9];
    if (roundsOut) *roundsOut = rounds;
    if (plainSizeOut) *plainSizeOut = plainSize;
    if (metadataOut) *metadataOut = metadata ?: @"";
    return YES;
}

BOOL NeoWCWXCDecryptFile(NSString *inputPath,
                         NSString *outputPath,
                         uint8_t *typeOut,
                         NSString **metadataOut,
                         NSError **error) {
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:inputPath error:error];
    uint64_t totalSize = [attributes[NSFileSize] unsignedLongLongValue];
    NSFileHandle *input = [NSFileHandle fileHandleForReadingAtPath:inputPath];
    NSMutableData *headerAndMetadata = nil;
    uint8_t type = 0;
    uint32_t rounds = 0;
    uint64_t expectedPlainSize = 0;
    NSString *metadata = nil;
    if (!input || !NeoWCWXCReadHeader(input, &headerAndMetadata, &type, &rounds,
                                      &expectedPlainSize, &metadata, error)) {
        [input closeFile];
        return NO;
    }
    NSUInteger payloadOffset = headerAndMetadata.length;
    if (totalSize < payloadOffset + 16 + NeoWCHMACLength) {
        [input closeFile];
        NeoWCSetEncryptionError(error, 24, @"WXCENC01 文件已截断");
        return NO;
    }
    uint64_t cipherLength = totalSize - payloadOffset - NeoWCHMACLength;
    if (cipherLength == 0 || cipherLength % kCCBlockSizeAES128 != 0) {
        [input closeFile];
        NeoWCSetEncryptionError(error, 24, @"WXCENC01 密文长度无效");
        return NO;
    }
    const uint8_t *header = headerAndMetadata.bytes;
    uint8_t keys[64] = {0};
    if (!NeoWCDeriveKeys(NeoWCWXCPassword, header + 24, rounds, NO, keys, error)) {
        [input closeFile];
        return NO;
    }

    CCHmacContext hmac;
    CCHmacInit(&hmac, kCCHmacAlgSHA256, keys + 32, 32);
    CCHmacUpdate(&hmac, headerAndMetadata.bytes, headerAndMetadata.length);
    uint64_t remaining = cipherLength;
    while (remaining > 0) {
        NSData *chunk = NeoWCReadFileData(input, (NSUInteger)MIN((uint64_t)NeoWCStreamChunkLength, remaining), error);
        if (!chunk || chunk.length == 0 || chunk.length > remaining) {
            [input closeFile];
            NeoWCSetEncryptionError(error, 24, @"读取 WXCENC01 密文失败");
            return NO;
        }
        CCHmacUpdate(&hmac, chunk.bytes, chunk.length);
        remaining -= chunk.length;
    }
    NSData *storedTag = NeoWCReadFileData(input, NeoWCHMACLength, error);
    uint8_t tag[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacFinal(&hmac, tag);
    if (storedTag.length != NeoWCHMACLength ||
        !NeoWCConstantTimeEqual(storedTag, [NSData dataWithBytes:tag length:sizeof(tag)])) {
        [input closeFile];
        NeoWCSetEncryptionError(error, 25, @"WXCENC01 校验失败，文件可能已被修改");
        return NO;
    }

    @try { [input seekToFileOffset:payloadOffset]; }
    @catch (__unused NSException *exception) {
        [input closeFile];
        NeoWCSetEncryptionError(error, 24, @"无法定位 WXCENC01 密文");
        return NO;
    }
    if (!NeoWCPrepareOutputPath(outputPath, error)) { [input closeFile]; return NO; }
    NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:outputPath];
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus cryptStatus = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                                   keys, 32, header + 40, &cryptor);
    BOOL success = output && cryptStatus == kCCSuccess;
    uint64_t writtenTotal = 0;
    remaining = cipherLength;
    while (success && remaining > 0) {
        NSData *chunk = NeoWCReadFileData(input, (NSUInteger)MIN((uint64_t)NeoWCStreamChunkLength, remaining), error);
        if (!chunk || chunk.length == 0) { success = NO; break; }
        remaining -= chunk.length;
        size_t capacity = CCCryptorGetOutputLength(cryptor, chunk.length, false);
        NSMutableData *plain = [NSMutableData dataWithLength:capacity];
        size_t written = 0;
        cryptStatus = CCCryptorUpdate(cryptor, chunk.bytes, chunk.length,
                                      plain.mutableBytes, plain.length, &written);
        if (cryptStatus != kCCSuccess) { success = NO; break; }
        plain.length = written;
        writtenTotal += written;
        if (written) success = NeoWCWriteFileData(output, plain, error);
    }
    if (success) {
        NSMutableData *finalData = [NSMutableData dataWithLength:kCCBlockSizeAES128];
        size_t finalLength = 0;
        cryptStatus = CCCryptorFinal(cryptor, finalData.mutableBytes, finalData.length, &finalLength);
        finalData.length = finalLength;
        success = cryptStatus == kCCSuccess && NeoWCWriteFileData(output, finalData, error);
        writtenTotal += finalLength;
    }
    if (cryptor) CCCryptorRelease(cryptor);
    [input closeFile];
    [output closeFile];
    if (!success || writtenTotal != expectedPlainSize) {
        [NSFileManager.defaultManager removeItemAtPath:outputPath error:nil];
        if (error && !*error) NeoWCSetEncryptionError(error, 26, @"WXCENC01 解密结果长度不一致");
        return NO;
    }
    if (typeOut) *typeOut = type;
    if (metadataOut) *metadataOut = metadata ?: @"";
    return YES;
}
