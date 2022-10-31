#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

# Common definitions for boot managers
BOOTMGR_TOOLS_BIN_DIR := prebuilts/bootmgr/tools/$(HOST_PREBUILT_TAG)/bin
BOOTMGR_PATH_OVERRIDE := PATH=$(BOOTMGR_TOOLS_BIN_DIR):$$PATH
BOOTMGR_XORRISO_EXEC := $(BOOTMGR_TOOLS_BIN_DIR)/xorriso

ifeq ($(TARGET_ARCH),arm64)
BOOTMGR_EFI_BOOT_FILENAME := BOOTAA64.EFI
else ifeq ($(TARGET_ARCH),x86_64)
BOOTMGR_EFI_BOOT_FILENAME := BOOTX64.EFI
endif

ifneq ($(LINEAGE_BUILD),)
BOOTMGR_ANDROID_DISTRIBUTION_NAME := LineageOS $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)
BOOTMGR_ANDROID_OTA_PACKAGE_NAME := lineage-$(LINEAGE_VERSION).zip
BOOTMGR_ARTIFACT_FILENAME_PREFIX := lineage-$(LINEAGE_VERSION)
BOOTMGR_THEME := lineage
else
LOCAL_BUILD_DATE := $(shell date -u +%Y%m%d)
BOOTMGR_ANDROID_DISTRIBUTION_NAME := Android $(PLATFORM_VERSION_LAST_STABLE) $(BUILD_ID)
BOOTMGR_ANDROID_OTA_PACKAGE_NAME := $(TARGET_PRODUCT)-ota.zip
BOOTMGR_ARTIFACT_FILENAME_PREFIX := Android-$(PLATFORM_VERSION_LAST_STABLE)-$(BUILD_ID)-$(LOCAL_BUILD_DATE)-$(TARGET_PRODUCT)
BOOTMGR_THEME := android
endif

ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
BOOTMGR_ANDROID_DISTRIBUTION_NAME += Car
else ifeq ($(PRODUCT_IS_ATV),true)
BOOTMGR_ANDROID_DISTRIBUTION_NAME += TV
endif

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
	ifneq ($(TARGET_KERNEL_VERSION),)
		BOOTMGR_ANDROID_DISTRIBUTION_NAME += \(Kernel version $(TARGET_KERNEL_VERSION)\)
	endif
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
	BOOTMGR_ANDROID_DISTRIBUTION_NAME += \(Kernel version $(TARGET_PREBUILT_KERNEL_USE)\)
else
	BOOTMGR_ANDROID_DISTRIBUTION_NAME += \(Emulator kernel version $(TARGET_PREBUILT_EMULATOR_KERNEL_USE)\)
endif

INSTALLED_ESPIMAGE_TARGET := $(TARGET_OUT_INTERMEDIATES)/CUSTOM_IMAGES/EFI.img
INSTALLED_ESPIMAGE_INSTALL_TARGET := $(PRODUCT_OUT)/$(BOOTMGR_ARTIFACT_FILENAME_PREFIX).img

INSTALLED_ESPIMAGE_TARGET_DEPS := \
	$(PRODUCT_OUT)/kernel \
	$(INSTALLED_COMBINED_RAMDISK_TARGET) \
	$(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)

INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS := \
	$(PRODUCT_OUT)/kernel \
	$(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET) \
	$(PRODUCT_OUT)/$(BOOTMGR_ANDROID_OTA_PACKAGE_NAME)

# $(1): output file
# $(2): list of contents to include
# $(3): purpose
define create-espimage
	/bin/dd if=/dev/zero of=$(1) bs=1M count=$$($(VIRT_COMMON_PATH)/.calc_fat32_img_size.sh $(2))
	$(BOOTMGR_TOOLS_BIN_DIR)/mformat -F -i $(1) -v "$(3)" ::
	$(foreach content,$(2),$(BOOTMGR_TOOLS_BIN_DIR)/mcopy -i $(1) -s $(content) :: &&)true
endef

# $(1): path to boot manager config file
define process-bootmgr-cfg-common
	sed -i "s|@BOOTMGR_ANDROID_DISTRIBUTION_NAME@|$(BOOTMGR_ANDROID_DISTRIBUTION_NAME)|g" $(1)
	sed -i "s|@BOOTMGR_EFI_BOOT_FILENAME@|$(BOOTMGR_EFI_BOOT_FILENAME)|g" $(1)
	sed -i "s|@STRIPPED_BOARD_KERNEL_CMDLINE@|$(strip $(BOARD_KERNEL_CMDLINE))|g" $(1)
endef

include $(call all-makefiles-under,$(LOCAL_PATH))

# Build boot manager images
ifneq ($(TARGET_BOOT_MANAGER),)

##### espimage #####

$(INSTALLED_ESPIMAGE_TARGET): $(INSTALLED_ESPIMAGE_TARGET_DEPS)
	$(hide) mkdir -p $(dir $@)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_DEPS))

.PHONY: espimage
espimage: $(INSTALLED_ESPIMAGE_TARGET)

.PHONY: espimage-nodeps
espimage-nodeps:
	@echo "make $(INSTALLED_ESPIMAGE_TARGET): ignoring dependencies"
	$(hide) mkdir -p $(dir $@)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_DEPS))

ALL_DEFAULT_INSTALLED_MODULES += $(PRODUCT_OUT)/EFI.img

##### espimage-install #####

$(INSTALLED_ESPIMAGE_INSTALL_TARGET): $(INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS)
	$(call make-espimage-install-target,$(INSTALLED_ESPIMAGE_INSTALL_TARGET),$(INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS))

.PHONY: espimage-install
espimage-install: $(INSTALLED_ESPIMAGE_INSTALL_TARGET)

.PHONY: espimage-install-nodeps
espimage-install-nodeps:
	@echo "make $(INSTALLED_ESPIMAGE_INSTALL_TARGET): ignoring dependencies"
	$(call make-espimage-install-target,$(INSTALLED_ESPIMAGE_INSTALL_TARGET),$(INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS))

endif # TARGET_BOOT_MANAGER