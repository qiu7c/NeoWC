ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeoWC

NeoWC_FILES = Tweak.xm $(wildcard Sources/*.m) $(wildcard Sources/*.S) $(wildcard Vendor/Silk/src/*.c)
NeoWC_CFLAGS = -IVendor/Silk/interface -IVendor/Silk/src -ffunction-sections -fdata-sections
NeoWC_OBJCFLAGS = -fobjc-arc
NeoWC_LDFLAGS = -Wl,-dead_strip
NeoWC_FRAMEWORKS = UIKit Foundation QuartzCore CoreImage Photos AVFoundation AVKit UniformTypeIdentifiers Metal MetalKit

include $(THEOS_MAKE_PATH)/tweak.mk
