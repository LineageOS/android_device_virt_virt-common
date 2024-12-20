#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)
ifneq ($(MAGISK_RAMDISK),)

# 1. Download latest Magisk apk
# 2. Extract to the following directory
# 3. `chown 755 prebuilts/magisk/lib/x86_64/lib*.so`
MAGISK_PREBUILT_DIR := prebuilts/magisk

MAGISK_LIB_DIR := $(MAGISK_PREBUILT_DIR)/lib/$(TARGET_CPU_ABI)
MAGISK_UTILS_DIR := $(MAGISK_PREBUILT_DIR)/lib/x86_64

MAGISKBOOT := $(MAGISK_UTILS_DIR)/libmagiskboot.so

MAGISK_INSTALL_RAMDISK_DIR := $(PRODUCT_OUT)/magisk

MAGISK_DEPS := \
	$(MAGISK_PREBUILT_DIR)/assets/stub.apk \
	$(wildcard $(MAGISK_LIB_DIR)/lib*.so) \
	$(wildcard $(MAGISK_UTILS_DIR)/lib*.so)

# According to "Ramdisk Patches" section on https://github.com/topjohnwu/Magisk/blob/master/scripts/boot_patch.sh
# `magiskinit` must be put on `/init`, because it attempts to copy itself from that path.
$(MAGISK_RAMDISK): $(MAGISK_DEPS)
	mkdir -p $(MAGISK_INSTALL_RAMDISK_DIR)/.backup
	mkdir -p $(MAGISK_INSTALL_RAMDISK_DIR)/overlay.d/sbin
	$(MAGISKBOOT) compress=xz $(MAGISK_LIB_DIR)/libmagisk.so $(MAGISK_INSTALL_RAMDISK_DIR)/overlay.d/sbin/magisk.xz
	$(MAGISKBOOT) compress=xz $(MAGISK_PREBUILT_DIR)/assets/stub.apk $(MAGISK_INSTALL_RAMDISK_DIR)/overlay.d/sbin/stub.xz
	$(MAGISKBOOT) compress=xz $(MAGISK_LIB_DIR)/libinit-ld.so $(MAGISK_INSTALL_RAMDISK_DIR)/overlay.d/sbin/init-ld.xz
	cp $(MAGISK_LIB_DIR)/libmagiskinit.so $(MAGISK_INSTALL_RAMDISK_DIR)/init
	chmod 755 $(MAGISK_INSTALL_RAMDISK_DIR)/init

	$(MKBOOTFS) -d $(TARGET_OUT) $(MAGISK_INSTALL_RAMDISK_DIR) > $(MAGISK_UNCOMPRESSED_RAMDISK)
	$(COMPRESSION_COMMAND) < $(MAGISK_UNCOMPRESSED_RAMDISK) > $@

endif # MAGISK_RAMDISK
endif # USES_DEVICE_VIRT_VIRT_COMMON
