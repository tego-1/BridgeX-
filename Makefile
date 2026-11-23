TARGET := iphone:clang:latest:15.0
ARCHS := arm64
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := BridgeX
BridgeX_FILES := Tweak.m
BridgeX_CFLAGS := -fobjc-arc -Wall -Wextra
BridgeX_FRAMEWORKS := Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
