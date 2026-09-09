#import "NeoWCVoiceEffectProcessor.h"
#import <math.h>
#import <stdbool.h>
#import <stdatomic.h>
#import <string.h>

#define NEOWC_EFFECT_MAX_CHANNELS 8
#define NEOWC_EFFECT_DELAY_SIZE 8192
#define NEOWC_EFFECT_TWO_PI 6.28318530717958647692

typedef struct {
    float delay[NEOWC_EFFECT_DELAY_SIZE];
    uint32_t writeIndex;
    float grainPhase;
    float robotPhase;
} NeoWCVoiceEffectChannelState;

static _Atomic(int) NeoWCVoiceEffectCurrentPreset;
static _Atomic(unsigned int) NeoWCVoiceEffectResetGeneration;
static NeoWCVoiceEffectChannelState NeoWCVoiceEffectStates[NEOWC_EFFECT_MAX_CHANNELS];
static unsigned int NeoWCVoiceEffectAppliedGeneration;
static int NeoWCVoiceEffectAppliedPreset;
static double NeoWCVoiceEffectAppliedSampleRate;

void NeoWCVoiceEffectSetPreset(NeoWCRealtimeVoiceEffect effect) {
    int resolved = MIN((int)NeoWCRealtimeVoiceEffectElectronic,
                       MAX((int)NeoWCRealtimeVoiceEffectOff, (int)effect));
    int previous = atomic_exchange(&NeoWCVoiceEffectCurrentPreset, resolved);
    if (previous != resolved) atomic_fetch_add(&NeoWCVoiceEffectResetGeneration, 1);
}

NeoWCRealtimeVoiceEffect NeoWCVoiceEffectPreset(void) {
    return (NeoWCRealtimeVoiceEffect)atomic_load(&NeoWCVoiceEffectCurrentPreset);
}

NSString *NeoWCVoiceEffectName(NeoWCRealtimeVoiceEffect effect) {
    switch (effect) {
        case NeoWCRealtimeVoiceEffectBright: return @"明亮女声";
        case NeoWCRealtimeVoiceEffectDeep: return @"低沉男声";
        case NeoWCRealtimeVoiceEffectRobot: return @"机器人";
        case NeoWCRealtimeVoiceEffectElectronic: return @"电音";
        default: return @"原声";
    }
}

void NeoWCVoiceEffectReset(void) {
    atomic_fetch_add(&NeoWCVoiceEffectResetGeneration, 1);
}

static inline float NeoWCVoiceEffectClamp(float value) {
    return fmaxf(-1.0f, fminf(1.0f, value));
}

static inline float NeoWCVoiceEffectReadDelay(NeoWCVoiceEffectChannelState *state,
                                               float delaySamples) {
    float position = (float)state->writeIndex - delaySamples;
    while (position < 0.0f) position += NEOWC_EFFECT_DELAY_SIZE;
    while (position >= NEOWC_EFFECT_DELAY_SIZE) position -= NEOWC_EFFECT_DELAY_SIZE;
    uint32_t first = (uint32_t)position;
    uint32_t second = (first + 1) % NEOWC_EFFECT_DELAY_SIZE;
    float fraction = position - (float)first;
    return state->delay[first] + (state->delay[second] - state->delay[first]) * fraction;
}

static inline float NeoWCVoiceEffectTriangle(float phase) {
    return phase < 0.5f ? phase * 2.0f : (1.0f - phase) * 2.0f;
}

static inline float NeoWCVoiceEffectPitchSample(NeoWCVoiceEffectChannelState *state,
                                                 float input,
                                                 float ratio,
                                                 float sampleRate) {
    state->delay[state->writeIndex] = input;
    float window = fminf(3000.0f, fmaxf(640.0f, sampleRate * 0.035f));
    float phase1 = state->grainPhase;
    float phase2 = phase1 + 0.5f;
    if (phase2 >= 1.0f) phase2 -= 1.0f;
    bool pitchUp = ratio > 1.0f;
    float delay1 = 48.0f + (pitchUp ? (1.0f - phase1) : phase1) * window;
    float delay2 = 48.0f + (pitchUp ? (1.0f - phase2) : phase2) * window;
    float weight1 = NeoWCVoiceEffectTriangle(phase1);
    float weight2 = NeoWCVoiceEffectTriangle(phase2);
    float shifted = NeoWCVoiceEffectReadDelay(state, delay1) * weight1 +
                    NeoWCVoiceEffectReadDelay(state, delay2) * weight2;
    state->writeIndex = (state->writeIndex + 1) % NEOWC_EFFECT_DELAY_SIZE;
    state->grainPhase += fabsf(ratio - 1.0f) / window;
    if (state->grainPhase >= 1.0f) state->grainPhase -= floorf(state->grainPhase);
    return NeoWCVoiceEffectClamp(shifted * 0.92f + input * 0.08f);
}

static inline float NeoWCVoiceEffectSample(NeoWCVoiceEffectChannelState *state,
                                            float input,
                                            NeoWCRealtimeVoiceEffect effect,
                                            float sampleRate) {
    switch (effect) {
        case NeoWCRealtimeVoiceEffectBright:
            return NeoWCVoiceEffectPitchSample(state, input, 1.259921f, sampleRate);
        case NeoWCRealtimeVoiceEffectDeep:
            return NeoWCVoiceEffectPitchSample(state, input, 0.793701f, sampleRate);
        case NeoWCRealtimeVoiceEffectRobot: {
            float carrier = sinf(state->robotPhase);
            state->robotPhase += (float)(NEOWC_EFFECT_TWO_PI * 72.0 / sampleRate);
            if (state->robotPhase >= (float)NEOWC_EFFECT_TWO_PI) {
                state->robotPhase -= (float)NEOWC_EFFECT_TWO_PI;
            }
            return NeoWCVoiceEffectClamp(input * (0.18f + carrier * 0.82f));
        }
        case NeoWCRealtimeVoiceEffectElectronic: {
            float carrier = sinf(state->robotPhase);
            state->robotPhase += (float)(NEOWC_EFFECT_TWO_PI * 36.0 / sampleRate);
            if (state->robotPhase >= (float)NEOWC_EFFECT_TWO_PI) {
                state->robotPhase -= (float)NEOWC_EFFECT_TWO_PI;
            }
            float quantized = roundf(input * 28.0f) / 28.0f;
            return NeoWCVoiceEffectClamp(quantized * (0.72f + carrier * 0.28f));
        }
        default:
            return input;
    }
}

void NeoWCVoiceEffectProcess(AudioStreamBasicDescription format,
                             UInt32 frames,
                             AudioBufferList *buffers) {
    NeoWCRealtimeVoiceEffect effect = NeoWCVoiceEffectPreset();
    if (effect == NeoWCRealtimeVoiceEffectOff || !buffers || frames == 0 ||
        format.mFormatID != kAudioFormatLinearPCM || format.mChannelsPerFrame == 0) return;
    bool float32 = (format.mFormatFlags & kAudioFormatFlagIsFloat) && format.mBitsPerChannel == 32;
    bool int16 = !(format.mFormatFlags & kAudioFormatFlagIsFloat) && format.mBitsPerChannel == 16;
    if (!float32 && !int16) return;

    double sampleRate = format.mSampleRate > 1000.0 ? format.mSampleRate : 48000.0;
    unsigned int generation = atomic_load(&NeoWCVoiceEffectResetGeneration);
    if (generation != NeoWCVoiceEffectAppliedGeneration ||
        NeoWCVoiceEffectAppliedPreset != effect ||
        fabs(NeoWCVoiceEffectAppliedSampleRate - sampleRate) > 1.0) {
        memset(NeoWCVoiceEffectStates, 0, sizeof(NeoWCVoiceEffectStates));
        NeoWCVoiceEffectAppliedGeneration = generation;
        NeoWCVoiceEffectAppliedPreset = effect;
        NeoWCVoiceEffectAppliedSampleRate = sampleRate;
    }

    bool nonInterleaved = (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0;
    UInt32 formatChannels = MAX((UInt32)1, format.mChannelsPerFrame);
    for (UInt32 bufferIndex = 0; bufferIndex < buffers->mNumberBuffers; bufferIndex++) {
        AudioBuffer *buffer = &buffers->mBuffers[bufferIndex];
        UInt32 bufferChannels = buffer->mNumberChannels > 0 ? buffer->mNumberChannels : formatChannels;
        UInt32 channels = nonInterleaved ? 1 : MAX((UInt32)1, bufferChannels);
        UInt32 availableFrames = int16
            ? buffer->mDataByteSize / (sizeof(SInt16) * channels)
            : buffer->mDataByteSize / (sizeof(float) * channels);
        UInt32 processFrames = MIN(frames, availableFrames);
        if (!buffer->mData) continue;
        for (UInt32 frame = 0; frame < processFrames; frame++) {
            for (UInt32 channel = 0; channel < channels; channel++) {
                UInt32 stateIndex = nonInterleaved ? bufferIndex : channel;
                if (stateIndex >= NEOWC_EFFECT_MAX_CHANNELS) continue;
                UInt32 index = frame * channels + channel;
                float input = int16 ? ((SInt16 *)buffer->mData)[index] / 32768.0f
                                    : ((float *)buffer->mData)[index];
                float output = NeoWCVoiceEffectSample(&NeoWCVoiceEffectStates[stateIndex], input,
                                                       effect, (float)sampleRate);
                if (int16) ((SInt16 *)buffer->mData)[index] = (SInt16)lrintf(output * 32767.0f);
                else ((float *)buffer->mData)[index] = output;
            }
        }
    }
}
