TARGET := iphone:clang:latest:15.0

ARCHS := arm64

THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := BridgeX

BridgeX_FILES := Tweak.m BridgeXDiagnostics.m BridgeXIPC.m BridgeXSettingsIPC.m

BridgeX_CFLAGS := -fobjc-arc -Wall -Wextra

BridgeX_FRAMEWORKS := Foundation

BUNDLE_NAME := BridgeXPrefs

BridgeXPrefs_FILES := Preferences/BridgeXRootListController.m

BridgeXPrefs_INSTALL_PATH := /Library/PreferenceBundles

BridgeXPrefs_RESOURCE_FILES := Preferences/Info.plist Preferences/Root.plist

BridgeXPrefs_FRAMEWORKS := UIKit

BridgeXPrefs_PRIVATE_FRAMEWORKS := Preferences

BridgeXPrefs_CFLAGS := -fobjc-arc -Wall -Wextra

include $(THEOS_MAKE_PATH)/tweak.mk

include $(THEOS_MAKE_PATH)/bundle.mk
