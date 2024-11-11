#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

# Include other makefiles
include $(call all-makefiles-under,$(LOCAL_PATH))

# Wi-Fi
include external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant_conf.mk

endif
