FINALPACKAGE=1
TARGET := iphone:clang:latest
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = MobileNotes
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FullNotes18
$(TWEAK_NAME)_CFLAGS = -fno-objc-arc -std=c++2b -Wno-module-import-in-extern-c
$(TWEAK_NAME)_FRAMEWORKS = Foundation
$(TWEAK_NAME)_FILES = init.mm

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/tool.mk
