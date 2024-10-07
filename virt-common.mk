#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# A/B
AB_OTA_UPDATER ?= true
ifeq ($(AB_OTA_UPDATER),true)
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    android.hardware.boot-service.virt_recovery \
    com.android.hardware.boot.virt \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
endif

# Audio
PRODUCT_PACKAGES += \
    com.android.hardware.audio

PRODUCT_COPY_FILES += \
    device/generic/goldfish/audio/policy/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    device/generic/goldfish/audio/policy/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml \
    hardware/interfaces/audio/aidl/default/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml

# Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.1-service.btlinux

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

# Boot manager
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bootmgr/rEFInd/refind-update-default_selection.sh:$(TARGET_COPY_OUT_VENDOR)/bin/refind-update-default_selection.sh

# Bootanimation
TARGET_SCREEN_WIDTH := 600
TARGET_SCREEN_HEIGHT := 600

# Dynamic partitions
PRODUCT_BUILD_SUPER_PARTITION := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Dalvik heap
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

# DHCP client
PRODUCT_PACKAGES += \
    virt_dhcpclient.recovery

# DLKM Loader
PRODUCT_PACKAGES += \
    dlkm_loader

# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.virt_recovery \
    fastbootd

# First stage init
PRODUCT_PACKAGES += \
    linker.vendor_ramdisk \
    resize2fs.vendor_ramdisk \
    shell_and_utilities_vendor_ramdisk \
    tune2fs.vendor_ramdisk

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software

# Graphics (Mesa)
PRODUCT_PACKAGES += \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    libglapi

# Graphics (Swiftshader)
PRODUCT_PACKAGES += \
    vulkan.pastel

PRODUCT_REQUIRES_INSECURE_EXECMEM_FOR_SWIFTSHADER := true

# Health
ifneq ($(LINEAGE_BUILD),)
PRODUCT_PACKAGES += \
    android.hardware.health-service.batteryless \
    android.hardware.health-service.batteryless_recovery
else
PRODUCT_PACKAGES += \
    android.hardware.health-service.cuttlefish_recovery \
    com.google.cf.health
endif

# Init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/init/init.low_performance.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.low_performance.rc \
    $(LOCAL_PATH)/configs/init/init.virt.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.virt.rc \
    $(LOCAL_PATH)/configs/init/ueventd.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc

# Input
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/input/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Generic.kl \
    $(LOCAL_PATH)/configs/input/uinput_multitouch_device.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/uinput_multitouch_device.idc

# Images
PRODUCT_BUILD_BOOT_IMAGE := true
PRODUCT_BUILD_RAMDISK_IMAGE := true
PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true

ifneq ($(AB_OTA_UPDATER),true)
PRODUCT_BUILD_RECOVERY_IMAGE := true
endif

# Kernel
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Keymint
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service

# Memtrack
PRODUCT_PACKAGES += \
    com.android.hardware.memtrack

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlays/overlay

ifneq ($(LINEAGE_BUILD),)
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlays/overlay-lineage
endif

PRODUCT_ENFORCE_RRO_TARGETS := *

PRODUCT_PACKAGES += \
    LowPerformanceSettingsProviderOverlay

# Page size
PRODUCT_MAX_PAGE_SIZE_SUPPORTED := 16384
PRODUCT_NO_BIONIC_PAGE_SIZE_MACRO := true

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.software.credentials.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.credentials.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

PRODUCT_PACKAGES += \
    android.hardware.bluetooth.prebuilt.xml \
    android.hardware.bluetooth_le.prebuilt.xml \
    android.hardware.ethernet.prebuilt.xml \
    android.hardware.usb.host.prebuilt.xml \
    android.hardware.wifi.prebuilt.xml \
    android.hardware.wifi.direct.prebuilt.xml \
    android.software.ipsec_tunnels.prebuilt.xml

ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/car_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/car_core_hardware.xml
else ifneq ($(PRODUCT_IS_ATV),true)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/pc_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/pc_core_hardware.xml
endif

PRODUCT_PACKAGES += \
    android.hardware.vulkan.level-1.prebuilt.xml \
    android.hardware.vulkan.compute-0.prebuilt.xml \
    android.hardware.vulkan.version-1_3.prebuilt.xml \
    android.software.vulkan.deqp.level-latest.prebuilt.xml \
    android.software.opengles.deqp.level-latest.prebuilt.xml

# Recovery
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bootmgr/rEFInd/refind-update-default_selection.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/refind-update-default_selection.sh \
    $(LOCAL_PATH)/configs/init/init.recovery.virt.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.virt.rc \
    $(LOCAL_PATH)/configs/init/ueventd.rc:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/ueventd.rc \
    $(LOCAL_PATH)/configs/scripts/create_partition_table.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/create_partition_table.sh \
    $(LOCAL_PATH)/configs/scripts/flash_persist_partition.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/flash_persist_partition.sh \
    device/google/cuttlefish/shared/config/cgroups.json:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/cgroups.json

# Sensors
$(call inherit-product, device/google/cuttlefish/shared/sensors/device_vendor.mk)

# Scoped Storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Shipping API level
# (Stays on 33 due to target-level)
PRODUCT_SHIPPING_API_LEVEL := 33

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Suspend blocker
PRODUCT_PACKAGES += \
    suspend_blocker

# Tablet to multitouch
PRODUCT_PACKAGES += \
    tablet2multitouch

# UFFD GC
PRODUCT_ENABLE_UFFD_GC := true

# Utilities
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/misc/pci.ids:$(TARGET_COPY_OUT_VENDOR)/pci.ids

PRODUCT_PACKAGES += \
    grub-editenv \
    grub-editenv.recovery \
    grub_boot_control \
    grub_boot_control.recovery \
    sgdisk.recovery

PRODUCT_PACKAGES_DEBUG += \
    tinycap \
    tinyhostless \
    tinymix \
    tinypcminfo \
    tinyplay

PRODUCT_HOST_PACKAGES += \
    grub-editenv \
    grub_boot_control

# VirtWifi
PRODUCT_PACKAGES += \
    setup_wifi

# Wakeupd
PRODUCT_PACKAGES += \
    wakeupd

# Wi-Fi
PRODUCT_COPY_FILES += \
    device/google/cuttlefish/shared/config/p2p_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant.conf \
    device/google/cuttlefish/shared/config/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

PRODUCT_PACKAGES += \
    hostapd \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_PACKAGES += \
    CuttlefishTetheringOverlay \
    CuttlefishWifiOverlay
