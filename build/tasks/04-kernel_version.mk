#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
	LOCAL_KERNEL_VERSION_DISPLAY_PREFIX := Kernel version
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
	LOCAL_KERNEL_VERSION_DISPLAY_PREFIX := Prebuilt kernel version
	ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/.kernel_version.txt),)
		LOCAL_KERNEL_VERSION := $(shell cat $(TARGET_PREBUILT_KERNEL_DIR)/.kernel_version.txt)
	else
		LOCAL_KERNEL_VERSION := $(TARGET_PREBUILT_KERNEL_USE)
	endif
else
	include $(KERNEL_ARTIFACTS_PATH)/kernel_version.mk
	LOCAL_KERNEL_VERSION_DISPLAY_PREFIX := Emulator kernel version
	LOCAL_KERNEL_VERSION := $(BOARD_KERNEL_VERSION)
endif

INSTALLED_KERNEL_VERSION_TXT_TARGET := $(PRODUCT_OUT)/.kernel_version.txt
INSTALLED_GRUB_KERNEL_VERSION_CFG_TARGET := $(PRODUCT_OUT)/.grub_kernel_version.cfg

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
# $(LOCAL_KERNEL_VERSION) is not available, can only use $(TARGET_KERNEL_VERSION)
LOCAL_KERNEL_VERSION_DISPLAY := \($(LOCAL_KERNEL_VERSION_DISPLAY_PREFIX) $(TARGET_KERNEL_VERSION)\)
$(INSTALLED_KERNEL_VERSION_TXT_TARGET): $(PRODUCT_OUT)/kernel
	cp $(PRODUCT_OUT)/obj/KERNEL_OBJ/include/config/kernel.release $@
$(INSTALLED_GRUB_KERNEL_VERSION_CFG_TARGET): $(INSTALLED_KERNEL_VERSION_TXT_TARGET)
	echo "set kernel_version_display=\"($(LOCAL_KERNEL_VERSION_DISPLAY_PREFIX) $(shell cat $(INSTALLED_KERNEL_VERSION_TXT_TARGET)))\"; export kernel_version_display" > $@
else
LOCAL_KERNEL_VERSION_DISPLAY := \($(LOCAL_KERNEL_VERSION_DISPLAY_PREFIX) $(LOCAL_KERNEL_VERSION)\)
$(INSTALLED_KERNEL_VERSION_TXT_TARGET):
	echo -n "$(LOCAL_KERNEL_VERSION)" > $@
$(INSTALLED_GRUB_KERNEL_VERSION_CFG_TARGET):
	echo "set kernel_version_display=\"($(LOCAL_KERNEL_VERSION_DISPLAY))\"; export kernel_version_display" > $@
endif

endif # USES_DEVICE_VIRT_VIRT_COMMON
