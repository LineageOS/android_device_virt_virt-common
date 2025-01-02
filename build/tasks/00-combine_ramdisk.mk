#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

# Combine ramdisk
INITRD_BOOTCONFIG_EXEC := $(HOST_OUT_EXECUTABLES)/initrd_bootconfig

ifneq ($(wildcard prebuilts/magisk/lib/x86_64/libmagiskboot.so),)
MAGISK_UNCOMPRESSED_RAMDISK := $(PRODUCT_OUT)/ramdisk-magisk.cpio
MAGISK_RAMDISK := $(PRODUCT_OUT)/ramdisk-magisk.img
endif

ifneq ($(AB_OTA_UPDATER),true)

INSTALLED_COMBINED_RAMDISK_TARGET := $(PRODUCT_OUT)/combined-ramdisk.img
INSTALLED_COMBINED_RAMDISK_TARGET_DEPS := $(PRODUCT_OUT)/ramdisk.img $(PRODUCT_OUT)/vendor_ramdisk.img $(MAGISK_RAMDISK)

$(INSTALLED_COMBINED_RAMDISK_TARGET): $(INSTALLED_COMBINED_RAMDISK_TARGET_DEPS) $(INITRD_BOOTCONFIG_EXEC) $(TARGET_BOOTCONFIG_FILES)
	cat $^ > $@-without_bootconfig
	$(INITRD_BOOTCONFIG_EXEC) attach --output $@ $@-without_bootconfig $(TARGET_BOOTCONFIG_FILES)

.PHONY: combined-ramdisk
combined-ramdisk: $(INSTALLED_COMBINED_RAMDISK_TARGET)

endif # AB_OTA_UPDATER

INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET := $(PRODUCT_OUT)/combined-ramdisk-recovery.img
INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET_DEPS := $(PRODUCT_OUT)/ramdisk-recovery.img $(PRODUCT_OUT)/vendor_ramdisk.img $(MAGISK_RAMDISK)

$(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET): $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET_DEPS) $(INITRD_BOOTCONFIG_EXEC) $(TARGET_BOOTCONFIG_FILES)
	cat $^ > $@-without_bootconfig
	$(INITRD_BOOTCONFIG_EXEC) attach --output $@ $@-without_bootconfig $(TARGET_BOOTCONFIG_FILES)

.PHONY: combined-ramdisk-recovery
combined-ramdisk-recovery: $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)

endif # USES_DEVICE_VIRT_VIRT_COMMON
