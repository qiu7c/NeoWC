#import "NeoWCSilkDecoder.h"
#include "SKP_Silk_SDK_API.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static NSString *const NeoWCSilkDecoderErrorDomain = @"com.qiu7c.neowc.silk-decoder";
enum {
    NeoWCSilkOutputSampleRate = 16000,
    NeoWCSilkMaxPacketBytes = 5120,
    NeoWCSilkMaxFramesPerPacket = 5,
    NeoWCSilkMaxOutputSamples = 9600,
};

typedef NS_ENUM(NSInteger, NeoWCSilkDecoderErrorCode) {
    NeoWCSilkDecoderErrorInvalidPath = 1,
    NeoWCSilkDecoderErrorInvalidHeader,
    NeoWCSilkDecoderErrorInvalidPacket,
    NeoWCSilkDecoderErrorSDKFailure,
    NeoWCSilkDecoderErrorWriteFailure,
};

static void NeoWCSilkSetError(NSError **error, NeoWCSilkDecoderErrorCode code, NSString *message) {
    if (error) *error = [NSError errorWithDomain:NeoWCSilkDecoderErrorDomain
                                            code:code
                                        userInfo:@{NSLocalizedDescriptionKey: message ?: @"Silk 解码失败"}];
}

static BOOL NeoWCSilkReadHeader(FILE *input) {
    static const uint8_t magic[] = { '#', '!', 'S', 'I', 'L', 'K', '_', 'V', '3' };
    uint8_t first = 0;
    if (fread(&first, 1, 1, input) != 1) return NO;
    if (first == 0x02) {
        uint8_t buffer[sizeof(magic)] = {0};
        return fread(buffer, 1, sizeof(buffer), input) == sizeof(buffer) &&
               memcmp(buffer, magic, sizeof(magic)) == 0;
    }
    if (first != magic[0]) return NO;
    uint8_t buffer[sizeof(magic) - 1] = {0};
    return fread(buffer, 1, sizeof(buffer), input) == sizeof(buffer) &&
           memcmp(buffer, magic + 1, sizeof(buffer)) == 0;
}

static BOOL NeoWCSilkReadPacketLength(FILE *input, int16_t *length, BOOL *finished) {
    uint8_t bytes[2] = {0};
    size_t count = fread(bytes, 1, sizeof(bytes), input);
    if (count == 0 && feof(input)) {
        *finished = YES;
        return YES;
    }
    if (count != sizeof(bytes)) return NO;
    *length = (int16_t)((uint16_t)bytes[0] | ((uint16_t)bytes[1] << 8));
    *finished = *length < 0;
    return YES;
}

static void NeoWCSilkWriteLE16(uint8_t *target, uint16_t value) {
    target[0] = (uint8_t)(value & 0xff);
    target[1] = (uint8_t)((value >> 8) & 0xff);
}

static void NeoWCSilkWriteLE32(uint8_t *target, uint32_t value) {
    target[0] = (uint8_t)(value & 0xff);
    target[1] = (uint8_t)((value >> 8) & 0xff);
    target[2] = (uint8_t)((value >> 16) & 0xff);
    target[3] = (uint8_t)((value >> 24) & 0xff);
}

static BOOL NeoWCSilkWriteWAVHeader(FILE *output, uint32_t pcmBytes) {
    uint8_t header[44] = {0};
    memcpy(header, "RIFF", 4);
    NeoWCSilkWriteLE32(header + 4, 36u + pcmBytes);
    memcpy(header + 8, "WAVEfmt ", 8);
    NeoWCSilkWriteLE32(header + 16, 16);
    NeoWCSilkWriteLE16(header + 20, 1);
    NeoWCSilkWriteLE16(header + 22, 1);
    NeoWCSilkWriteLE32(header + 24, (uint32_t)NeoWCSilkOutputSampleRate);
    NeoWCSilkWriteLE32(header + 28, (uint32_t)NeoWCSilkOutputSampleRate * 2u);
    NeoWCSilkWriteLE16(header + 32, 2);
    NeoWCSilkWriteLE16(header + 34, 16);
    memcpy(header + 36, "data", 4);
    NeoWCSilkWriteLE32(header + 40, pcmBytes);
    return fseek(output, 0, SEEK_SET) == 0 && fwrite(header, 1, sizeof(header), output) == sizeof(header);
}

BOOL NeoWCSilkDecodeFileToWAV(NSString *sourcePath, NSString *destinationPath, NSError **error) {
    if (sourcePath.length == 0 || destinationPath.length == 0) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorInvalidPath, @"语音文件路径无效");
        return NO;
    }
    FILE *input = fopen(sourcePath.fileSystemRepresentation, "rb");
    if (!input) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorInvalidPath, @"无法读取 Silk 语音文件");
        return NO;
    }
    FILE *output = NULL;
    void *decoder = NULL;
    BOOL success = NO;
    if (!NeoWCSilkReadHeader(input)) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorInvalidHeader, @"不是受支持的 Silk V3 语音文件");
        goto cleanup;
    }
    output = fopen(destinationPath.fileSystemRepresentation, "wb+");
    if (!output) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorWriteFailure, @"无法创建临时 WAV 文件");
        goto cleanup;
    }
    uint8_t emptyHeader[44] = {0};
    if (fwrite(emptyHeader, 1, sizeof(emptyHeader), output) != sizeof(emptyHeader)) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorWriteFailure, @"无法写入临时 WAV 文件");
        goto cleanup;
    }
    int32_t decoderSize = 0;
    if (SKP_Silk_SDK_Get_Decoder_Size(&decoderSize) != 0 || decoderSize <= 0) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorSDKFailure, @"无法初始化 Silk 解码器");
        goto cleanup;
    }
    decoder = calloc(1, (size_t)decoderSize);
    if (!decoder || SKP_Silk_SDK_InitDecoder(decoder) != 0) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorSDKFailure, @"无法初始化 Silk 解码器");
        goto cleanup;
    }
    SKP_SILK_SDK_DecControlStruct control;
    memset(&control, 0, sizeof(control));
    control.API_sampleRate = NeoWCSilkOutputSampleRate;
    control.framesPerPacket = 1;
    uint8_t payload[NeoWCSilkMaxPacketBytes];
    int16_t samples[NeoWCSilkMaxOutputSamples];
    uint64_t totalPCMBytes = 0;
    for (;;) {
        int16_t packetLength = 0;
        BOOL finished = NO;
        if (!NeoWCSilkReadPacketLength(input, &packetLength, &finished)) {
            NeoWCSilkSetError(error, NeoWCSilkDecoderErrorInvalidPacket, @"Silk 数据包长度不完整");
            goto cleanup;
        }
        if (finished) break;
        if (packetLength <= 0 || packetLength > NeoWCSilkMaxPacketBytes ||
            fread(payload, 1, (size_t)packetLength, input) != (size_t)packetLength) {
            NeoWCSilkSetError(error, NeoWCSilkDecoderErrorInvalidPacket, @"Silk 数据包损坏或不完整");
            goto cleanup;
        }
        int frames = 0;
        do {
            int16_t sampleCount = 0;
            int result = SKP_Silk_SDK_Decode(decoder, &control, 0, payload, packetLength,
                                              samples, &sampleCount);
            if (result != 0 || sampleCount <= 0 || sampleCount > NeoWCSilkMaxOutputSamples) {
                NeoWCSilkSetError(error, NeoWCSilkDecoderErrorSDKFailure, @"Silk 音频帧解码失败");
                goto cleanup;
            }
            size_t bytes = (size_t)sampleCount * sizeof(int16_t);
            if (totalPCMBytes + bytes > UINT32_MAX || fwrite(samples, 1, bytes, output) != bytes) {
                NeoWCSilkSetError(error, NeoWCSilkDecoderErrorWriteFailure, @"写入临时 WAV 文件失败");
                goto cleanup;
            }
            totalPCMBytes += bytes;
            frames++;
            if (frames > NeoWCSilkMaxFramesPerPacket) {
                NeoWCSilkSetError(error, NeoWCSilkDecoderErrorInvalidPacket, @"Silk 数据包包含过多音频帧");
                goto cleanup;
            }
        } while (control.moreInternalDecoderFrames);
    }
    if (totalPCMBytes == 0 || !NeoWCSilkWriteWAVHeader(output, (uint32_t)totalPCMBytes) || fflush(output) != 0) {
        NeoWCSilkSetError(error, NeoWCSilkDecoderErrorWriteFailure, @"生成临时 WAV 文件失败");
        goto cleanup;
    }
    success = YES;

cleanup:
    if (decoder) free(decoder);
    if (output) fclose(output);
    fclose(input);
    if (!success) [NSFileManager.defaultManager removeItemAtPath:destinationPath error:nil];
    return success;
}
