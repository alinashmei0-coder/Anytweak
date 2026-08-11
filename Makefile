ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

TARGET = iphone:clang:latest:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DumpMaster

# ✅ استهداف جميع التطبيقات
BUNDLE_ID = com.apple.UIKit
INSTALL_TARGET_PROCESSES = SpringBoard

$(TWEAK_NAME)_FILES = Tweak.xm DumpMaster.m
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -w
$(TWEAK_NAME)_LIBRARIES += substrate

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS)/makefiles/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard || :"
