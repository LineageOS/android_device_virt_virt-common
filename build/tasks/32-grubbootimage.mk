#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

ifeq ($(AB_OTA_UPDATER),true)
ifeq ($(TARGET_BOOT_MANAGER),grub)

##### grubbootimage #####

$(INSTALLED_GRUB_BOOT_IMAGE_TARGET): $(INSTALLED_GRUB_BOOT_IMAGE_TARGET_DEPS)
	$(call pretty,"Target grub_boot image: $@")
	$(call create-fat32image,$@,$(INSTALLED_GRUB_BOOT_IMAGE_TARGET_DEPS),grub_boot)

.PHONY: grubbootimage
grubbootimage: $(INSTALLED_GRUB_BOOT_IMAGE_TARGET)

endif # TARGET_BOOT_MANAGER
endif # AB_OTA_UPDATER

endif # USES_DEVICE_VIRT_VIRT_COMMON
