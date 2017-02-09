include theos/makefiles/common.mk
export ARCHS = armv7 arm64
export SDKVERSION = 9.0
TWEAK_NAME = Genous
Genous_FILES = tweak.xm movingview.mm genousvw.mm
Genous_FRAMEWORKS = Foundation UIKit CoreGraphics CoreImage QuartzCore
ADDITIONAL_OBJCFLAGS = -Wno-deprecated-declarations
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
include $(THEOS_MAKE_PATH)/aggregate.mk
