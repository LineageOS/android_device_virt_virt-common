#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(TARGET_BOOT_MANAGER),linux_efi_stub)

ifneq ($(EMULATOR_KERNEL_FILE),)
$(error Emulator kernels does not have EFI stub)
endif

INSTALLED_ESPIMAGE_TARGET_DEPS += \
	$(TARGET_EFI_BOOT_SCRIPTS)

INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS += \
	$(TARGET_EFI_INSTALL_SCRIPTS)

EFISTUB_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/EFISTUB_OBJ
EFISTUB_WORKDIR_ESP := $(EFISTUB_WORKDIR_BASE)/esp
EFISTUB_WORKDIR_INSTALL := $(EFISTUB_WORKDIR_BASE)/install

##### espimage #####

# $(1): output file
# $(2): files to include (unused)
define make-espimage-target
	$(call pretty,"Target EFI System Partition image: $(1)")
	mkdir -p $(EFISTUB_WORKDIR_ESP)/fsroot
	cp $(PRODUCT_OUT)/kernel $(EFISTUB_WORKDIR_ESP)/fsroot/kernel.efi
	cp $(TARGET_EFI_BOOT_SCRIPTS) $(EFISTUB_WORKDIR_ESP)/fsroot/
	$(foreach f,$(notdir $(TARGET_EFI_BOOT_SCRIPTS)),\
		$(call process-bootmgr-cfg-common,$(EFISTUB_WORKDIR_ESP)/fsroot/$(f)) &&)true
	$(call create-espimage,$(1),$(EFISTUB_WORKDIR_ESP)/fsroot/* $(INSTALLED_COMBINED_RAMDISK_TARGET) $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET),boot)
endef

##### espimage-install #####

# $(1): output file
# $(2): files to include (unused)
define make-espimage-install-target
	$(call pretty,"Target installer ESP image: $(1)")
	mkdir -p $(EFISTUB_WORKDIR_INSTALL)/fsroot
	cp $(PRODUCT_OUT)/kernel $(EFISTUB_WORKDIR_INSTALL)/fsroot/kernel.efi
	cp $(TARGET_EFI_INSTALL_SCRIPTS) $(EFISTUB_WORKDIR_INSTALL)/fsroot/
	$(foreach f,$(notdir $(TARGET_EFI_INSTALL_SCRIPTS)),\
		$(call process-bootmgr-cfg-common,$(EFISTUB_WORKDIR_INSTALL)/fsroot/$(f)))
	$(call create-espimage,$(1),$(EFISTUB_WORKDIR_INSTALL)/fsroot/* $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET) $(PRODUCT_OUT)/$(BOOTMGR_ANDROID_OTA_PACKAGE_NAME),install)
endef

endif # TARGET_BOOT_MANAGER
