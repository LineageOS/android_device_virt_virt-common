#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_REFIND_PATH := $(VIRT_COMMON_PATH)/bootmgr/rEFInd

ifeq ($(TARGET_BOOT_MANAGER),rEFInd)
INSTALLED_ESPIMAGE_TARGET_DEPS += \
	$(TARGET_REFIND_BOOT_CONFIG)

INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS += \
	$(TARGET_REFIND_INSTALL_CONFIG)

REFIND_PREBUILT_DIR := prebuilts/bootmgr/rEFInd

REFIND_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/REFIND_OBJ
REFIND_WORKDIR_ESP := $(REFIND_WORKDIR_BASE)/esp
REFIND_WORKDIR_INSTALL := $(REFIND_WORKDIR_BASE)/install

ifeq ($(TARGET_ARCH),arm64)
REFIND_ARCH := aa64
else ifeq ($(TARGET_ARCH),x86_64)
REFIND_ARCH := x64
endif

# $(1): path to /EFI/BOOT
define copy-refind-files-to-efi-boot
	mkdir -p $(1)/drivers_$(REFIND_ARCH)
	$(foreach drv,ext4,\
		cp $(REFIND_PREBUILT_DIR)/refind/drivers_$(REFIND_ARCH)/$(drv)_$(REFIND_ARCH).efi $(1)/drivers_$(REFIND_ARCH)/ &&\
	)true
	cp $(REFIND_PREBUILT_DIR)/refind/refind_$(REFIND_ARCH).efi $(1)/$(BOOTMGR_EFI_BOOT_FILENAME)
	cp -r $(REFIND_PREBUILT_DIR)/refind/icons $(1)/
	cp $(REFIND_PREBUILT_DIR)/LICENSE.txt $(1)/
endef

# $(1): output file
# $(2): files to include
# $(3): workdir
# $(4): purpose (boot or install)
# $(5): configuration file
define make-espimage
	$(call copy-refind-files-to-efi-boot,$(3)/fsroot/EFI/BOOT)

	cp $(5) $(3)/fsroot/EFI/BOOT/refind.conf
	$(call process-bootmgr-cfg-common,$(3)/fsroot/EFI/BOOT/refind.conf)

	$(if $(LINEAGE_BUILD),\
		cp $(COMMON_REFIND_PATH)/icons/os_lineage.png $(3)/fsroot/EFI/BOOT/icons/ && \
		sed -i "s|os_linux.png|os_lineage.png|g" $(3)/fsroot/EFI/BOOT/refind.conf \
	)

	$(call create-fat32image,$(1),$(3)/fsroot/EFI $(2),$(4))
endef

##### espimage #####

# $(1): output file
# $(2): files to include
define make-espimage-target
	$(call pretty,"Target EFI System Partition image: $(1)")
	$(call make-espimage,$(1),$(2),$(REFIND_WORKDIR_ESP),boot,$(TARGET_REFIND_BOOT_CONFIG))
endef

##### espimage-install #####

# $(1): output file
# $(2): files to include
define make-espimage-install-target
	$(call pretty,"Target installer ESP image: $(1)")
	$(call make-espimage,$(1),$(2),$(REFIND_WORKDIR_INSTALL),install,$(TARGET_REFIND_INSTALL_CONFIG))
endef

endif # TARGET_BOOT_MANAGER
