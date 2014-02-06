LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_MODULE := emailchecker
LOCAL_CFLAGS := -std=gnu++11 -fno-exceptions -fno-rtti

#LOCAL_CPP_FEATURES += rtti

EMAILCHECKER_SOURCES = $(shell find $(LOCAL_PATH)/../../common/ -name "*.cpp"|sed 's+$(LOCAL_PATH)/++')

ANDROID_SOURCES = $(shell find $(LOCAL_PATH)/../jni -name "*.cpp"|sed 's+$(LOCAL_PATH)/++')
$($warning "HEY: " $(ANDROID_SOURCES))

LOCAL_SRC_FILES := $(EMAILCHECKER_SOURCES) $(ANDROID_SOURCES)
LOCAL_C_INCLUDES := $(LOCAL_PATH)/ $(LOCAL_PATH)/../../common/

include $(BUILD_SHARED_LIBRARY)

#$(call import-module,unittestpp)
