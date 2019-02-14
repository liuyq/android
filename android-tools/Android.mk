TOP_PATH := $(call my-dir)

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := adbovertcpip.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_OUT_EXECUTABLES)
LOCAL_SRC_FILES := adbovertcpip.sh
#LOCAL_MODULE_TAGS := debug
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := adbroot.sh
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_OUT_EXECUTABLES)
LOCAL_SRC_FILES := adbroot.sh
#LOCAL_MODULE_TAGS := debug
include $(BUILD_PREBUILT)

#-include $(TOP_PATH)/sl/Android.mk
#-include $(TOP_PATH)/static-binary/src/Android.mk
#-include $(TOP_PATH)/apks/Android.mk
