#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

USES_DEVICE_VIRT_VIRT_COMMON := true
VIRT_COMMON_PATH := device/virt/virt-common

# Boot manager
TARGET_GRUB_BOOT_CONFIGS := $(VIRT_COMMON_PATH)/bootmgr/grub/grub-boot.cfg
TARGET_GRUB_INSTALL_CONFIGS := $(VIRT_COMMON_PATH)/bootmgr/grub/grub-install.cfg

# Bootloader
BOARD_BOOT_HEADER_VERSION := 3
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
TARGET_NO_BOOTLOADER := true

# Fastboot
ifeq ($(AB_OTA_UPDATER),true)
TARGET_BOARD_FASTBOOT_INFO_FILE := $(VIRT_COMMON_PATH)/configs/misc/fastboot-info_ab.txt
else
TARGET_BOARD_FASTBOOT_INFO_FILE := $(VIRT_COMMON_PATH)/configs/misc/fastboot-info_a.txt
endif

# Filesystem
BOARD_EXT4_SHARE_DUP_BLOCKS :=
BOARD_EROFS_COMPRESSOR := none
BOARD_EROFS_SHARE_DUP_BLOCKS := true
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EXT4 := true

# Graphics (Mesa)
BOARD_MESA3D_USES_MESON_BUILD := true

ifneq ($(wildcard external/llvm-project/Android.bp),)
BUILD_BROKEN_PLUGIN_VALIDATION := \
    soong-llvm12 \
    soong-llvm17 \
    soong-llvm18 \
    soong-llvm19
BOARD_MESA3D_GALLIUM_DRIVERS := swrast
BOARD_MESA3D_VULKAN_DRIVERS := swrast
endif

# Graphics (Swiftshader)
include device/google/cuttlefish/shared/swiftshader/BoardConfig.mk

# Init
TARGET_INIT_VENDOR_LIB ?= //$(VIRT_COMMON_PATH):init_virt
TARGET_RECOVERY_DEVICE_MODULES ?= init_virt

# Kernel
BOARD_KERNEL_CMDLINE := \
    log_buf_len=4M \
    loop.max_part=7 \
    printk.devkmsg=on \
    rw \
    androidboot.boot_devices=any \
    androidboot.first_stage_console=0 \
    androidboot.hypervisor.version=1 \
    androidboot.hypervisor.vm.supported=1 \
    androidboot.hypervisor.protected_vm.supported=0 \
    androidboot.verifiedbootstate=orange

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
BOARD_VENDOR_KERNEL_MODULES_LOAD := \
    btusb.ko \
    cfg80211.ko \
    virt_wifi.ko
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    lineageos/peripheral/bluetooth.config \
    lineageos/peripheral/wifi.config \
    lineageos/feature/fbcon.config
endif

# Partitions
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_USES_METADATA_PARTITION := true

ifneq ($(AB_OTA_UPDATER),true)
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 52428800 # 50 MB
endif

DLKM_PARTITIONS := system_dlkm vendor_dlkm
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor
ALL_PARTITIONS := $(DLKM_PARTITIONS) $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

$(foreach p, $(DLKM_PARTITIONS), \
    $(eval BOARD_USES_$(call to-upper, $(p))IMAGE := true))

TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE ?= ext4
ifeq ($(TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE),ext4)
    BOARD_SUPER_PARTITION_SIZE := 4294967296 # 4 GB
    BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := 8192
    BOARD_PRODUCTIMAGE_EXTFS_INODE_COUNT := 6144
    BOARD_SYSTEM_EXTIMAGE_EXTFS_INODE_COUNT := 4096
    BOARD_VENDORIMAGE_EXTFS_INODE_COUNT := 2048
    BOARD_ODMIMAGE_EXTFS_INODE_COUNT := 1024
    $(foreach p, $(call to-upper, $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)), \
        $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 134217728)) # 128 MB
    ifneq ($(WITH_GMS),true)
        BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE := 1073741824 # 1 GB
    endif
else ifeq ($(TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE),erofs)
    BOARD_SUPER_PARTITION_SIZE := 3221225472 # 3 GB
else
    $(error TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE is invalid)
endif

ifeq ($(AB_OTA_UPDATER),true)
BOARD_SUPER_PARTITION_SIZE := 12884901888 # 12 GB
endif

BOARD_SUPER_PARTITION_GROUPS := virt_dynamic_partitions
BOARD_VIRT_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_VIRT_DYNAMIC_PARTITIONS_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 4194304 )

$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := $(TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE)) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

ifeq ($(AB_OTA_UPDATER),true)
ifeq ($(TARGET_BOOT_MANAGER),grub)
AB_OTA_PARTITIONS := \
    $(ALL_PARTITIONS) \
    boot \
    EFI \
    grub_boot
endif
endif

# Platform
TARGET_BOARD_PLATFORM := virt

# Properties
TARGET_PRODUCT_PROP := $(VIRT_COMMON_PATH)/configs/properties/product.prop
TARGET_VENDOR_PROP := $(VIRT_COMMON_PATH)/configs/properties/vendor.prop

ifneq ($(PRODUCT_IS_ATV),true)
ifneq ($(PRODUCT_IS_AUTOMOTIVE),true)
TARGET_VENDOR_PROP += \
    $(VIRT_COMMON_PATH)/configs/properties/vendor_bluetooth_profiles.prop
endif
endif

# Ramdisk
BOARD_RAMDISK_USE_LZ4 := true

# Recovery
TARGET_RECOVERY_UI_LIB := librecovery_ui_virt

ifeq ($(AB_OTA_UPDATER),true)
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
TARGET_NO_RECOVERY := true
endif

# Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(VIRT_COMMON_PATH)

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Security patch level
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS := \
    $(VIRT_COMMON_PATH)/sepolicy/vendor \
    $(VIRT_COMMON_PATH)/sepolicy/vendor/cuttlefish_graphics \
    device/google/cuttlefish/shared/sensors/sepolicy \
    device/google/cuttlefish/shared/swiftshader/sepolicy \
    device/google/cuttlefish/shared/virgl/sepolicy \
    external/minigbm/cros_gralloc/sepolicy

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(VIRT_COMMON_PATH)/sepolicy/private

# VINTF
DEVICE_MANIFEST_FILE := \
    $(VIRT_COMMON_PATH)/configs/vintf/manifest.xml

# Wi-Fi
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X
