#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Defaults
AB_OTA_UPDATER ?= true

# Inherit from mainline/common
TARGET_BOOT_HAL := grub
TARGET_ENABLE_LOGCAT_TO_SERIAL := true
TARGET_GRAPHICS := mesa
TARGET_HAS_BATTERY := false
TARGET_HAS_VIBRATOR := false
TARGET_LIGHT_HAL := none
TARGET_SENSORS_HAL := cuttlefish
TARGET_SUPPORTS_SUSPEND := false
TARGET_SUPPORTS_USB_ACCESSORY_MODE := false
include device/mainline/common/optional/options.mk
$(call inherit-product, device/mainline/common/mainline_common.mk)

VIRT_COMMON_PATH := device/virt/virt-common

# A/B
ifeq ($(AB_OTA_UPDATER),true)
AB_OTA_POSTINSTALL_CONFIG += \
    FILESYSTEM_TYPE_system=ext4

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call soong_config_set,VIRT_PREINSTALL_CHECK,AB_OTA_UPDATER,$(AB_OTA_UPDATER))
endif

# Audio
PRODUCT_PACKAGES += \
    setup_sound_card

PRODUCT_COPY_FILES += \
    device/google/cuttlefish/shared/config/audio/policy/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    device/google/cuttlefish/shared/config/audio/policy/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_with_le_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_with_le_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml

# Bluetooth
ifneq ($(PRODUCT_IS_ATV),true)
ifneq ($(PRODUCT_IS_AUTOMOTIVE),true)
# Set the Bluetooth Class of Device
# Service Field: 0x1A -> 26
#    Bit 17: Networking
#    Bit 19: Capturing
#    Bit 20: Object Transfer
# MAJOR_CLASS: 0x01 -> 1 (Computer)
# MINOR_CLASS: 0x04 -> 4 (Desktop workstation)
PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.device.class_of_device=26,1,4
endif
endif

# Bootanimation
ifeq ($(PRODUCT_IS_GO),true)
TARGET_SCREEN_WIDTH := 100
TARGET_SCREEN_HEIGHT := 100
else
TARGET_SCREEN_WIDTH := 600
TARGET_SCREEN_HEIGHT := 600
endif

# Dynamic partitions
PRODUCT_BUILD_SUPER_PARTITION := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Dalvik heap
ifeq ($(PRODUCT_IS_GO),true)
$(call inherit-product, frameworks/native/build/phone-xhdpi-1024-dalvik-heap.mk)
else
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)
endif

# DHCP client
PRODUCT_PACKAGES += \
    virt_dhcpclient.recovery

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.virt_recovery

# Firmware
PRODUCT_PACKAGES += \
    vendor_firmware_mnt_placeholder_symlink

# First stage init
PRODUCT_PACKAGES += \
    linker.vendor_ramdisk \
    resize2fs.vendor_ramdisk \
    shell_and_utilities_vendor_ramdisk \
    tune2fs.vendor_ramdisk

# Graphics (Mesa)
TARGET_MESA_DO_NOT_SET_AS_DEFAULT := true

# Graphics (Swiftshader)
PRODUCT_PACKAGES += \
    vulkan.pastel

PRODUCT_REQUIRES_INSECURE_EXECMEM_FOR_SWIFTSHADER := true

# HIDL
PRODUCT_PACKAGES_SHIPPING_API_LEVEL_34 += \
    vndservicemanager

# Init
PRODUCT_COPY_FILES += \
    $(VIRT_COMMON_PATH)/configs/init/init.low_performance.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.low_performance.rc \
    $(VIRT_COMMON_PATH)/configs/init/init.virt.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.virt.rc \
    $(VIRT_COMMON_PATH)/configs/init/ueventd.virt.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.virt.rc

PRODUCT_COPY_FILES += \
    $(VIRT_COMMON_PATH)/configs/init/device_virt_settings.rc:$(TARGET_COPY_OUT_PRODUCT)/etc/init/device_virt_settings.rc \
    $(VIRT_COMMON_PATH)/configs/scripts/device_virt_settings.sh:$(TARGET_COPY_OUT_PRODUCT)/bin/device_virt_settings.sh

$(call soong_config_set,libinit,vendor_init_lib,//$(VIRT_COMMON_PATH):init_virt)

# Input
PRODUCT_COPY_FILES += \
    $(VIRT_COMMON_PATH)/configs/input/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Generic.kl \
    $(VIRT_COMMON_PATH)/configs/input/virt_tablet2multitouch.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/virt_tablet2multitouch.idc

# Images
PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true

ifneq ($(AB_OTA_UPDATER),true)
PRODUCT_BUILD_RECOVERY_IMAGE := true
endif

# Kernel
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Media
PRODUCT_COPY_FILES += \
    device/google/cuttlefish/shared/config/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    device/google/cuttlefish/shared/config/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_vendor.xml

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(VIRT_COMMON_PATH)/overlays/overlay

ifeq ($(PRODUCT_IS_ATV),true)
# nothing
else ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
# nothing
else ifeq ($(PRODUCT_IS_GO),true)
# nothing
else
PRODUCT_PACKAGE_OVERLAYS += \
    $(VIRT_COMMON_PATH)/overlays/product_overlay-tablet
endif

ifneq ($(LINEAGE_BUILD),)
DEVICE_PACKAGE_OVERLAYS += \
    $(VIRT_COMMON_PATH)/overlays/overlay-lineage
endif

PRODUCT_PACKAGES += \
    AodDefaultOnOverlay \
    LowPerformanceSettingsProviderOverlay

# Page size
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := true

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

PRODUCT_PACKAGES += \
    android.hardware.bluetooth.prebuilt.xml \
    android.hardware.bluetooth_le.prebuilt.xml \
    android.hardware.ethernet.prebuilt.xml \
    android.hardware.usb.host.prebuilt.xml \
    android.hardware.wifi.prebuilt.xml \
    android.hardware.wifi.direct.prebuilt.xml

ifeq ($(PRODUCT_IS_ATV),true)
# nothing
else ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/car_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/car_core_hardware.xml
else ifeq ($(PRODUCT_IS_GO),true)
# nothing
else
PRODUCT_COPY_FILES += \
    $(VIRT_COMMON_PATH)/configs/misc/android.hardware.type.pc.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.hardware.type.pc.xml \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml
endif

PRODUCT_PACKAGES += \
    android.hardware.vulkan.level-1.prebuilt.xml \
    android.hardware.vulkan.compute-0.prebuilt.xml \
    android.hardware.vulkan.version-1_3.prebuilt.xml \
    android.software.vulkan.deqp.level-latest.prebuilt.xml \
    android.software.opengles.deqp.level-latest.prebuilt.xml

# Recovery
PRODUCT_COPY_FILES += \
    $(VIRT_COMMON_PATH)/configs/init/init.recovery.virt.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.virt.rc \
    $(VIRT_COMMON_PATH)/configs/init/ueventd.virt.rc:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/ueventd.virt.rc \
    $(VIRT_COMMON_PATH)/configs/scripts/create_partition_table.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/create_partition_table.sh \
    $(VIRT_COMMON_PATH)/configs/scripts/flash_persist_partition.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/flash_persist_partition.sh \
    device/google/cuttlefish/shared/config/cgroups.json:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/cgroups.json

PRODUCT_PACKAGES += \
    preinstall_check

# Scoped Storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(VIRT_COMMON_PATH)

# Tablet to multitouch
PRODUCT_PACKAGES += \
    tablet2multitouch \
    tablet2multitouch_recovery

# Utilities
PRODUCT_COPY_FILES += \
    $(VIRT_COMMON_PATH)/configs/misc/pci.ids:$(TARGET_COPY_OUT_VENDOR)/pci.ids

PRODUCT_PACKAGES += \
    grub-editenv \
    grub-editenv.recovery \
    grub_boot_control \
    grub_boot_control.recovery \
    sgdisk.recovery

PRODUCT_HOST_PACKAGES += \
    grub-editenv \
    grub_boot_control \
    grub_i386-pc_img_patch

# Virtualization
$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)

# VirtWifi
PRODUCT_PACKAGES += \
    setup_wifi

# Wi-Fi
PRODUCT_COPY_FILES += \
    device/google/cuttlefish/shared/config/p2p_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant.conf \
    device/google/cuttlefish/shared/config/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant_template.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf

PRODUCT_PACKAGES += \
    CuttlefishTetheringOverlay \
    CuttlefishWifiOverlay

# Window extensions
ifeq ($(LINEAGE_BUILD),)
$(call inherit-product, build/target/product/window_extensions.mk)
endif
