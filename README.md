# Android common device tree for Virtual Machines

The device tree is currently WIP, Not suitable for normal use.

```
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
```

# TODO
- Support for USB Camera, and WiFi
- 16K pagesize

# List of optional extra boot parameters

| Parameter | Possible values | Description |
| --------- | --------------- | ----------- |
| `androidboot.graphics` | `mesa` or `swiftshader` | Graphics stack to use. Default is `mesa`. |
| `androidboot.lcd_density` | `<DPI>` | Screen density. Default is `160`. |
| `androidboot.low_perf` | `1` | Add this to enable low performance optimizations. |
| `androidboot.nobootanim` | `1` | Add this to disable boot animation. |
| `androidboot.wifi_impl` | `virt_wifi` | Set this to `virt_wifi` to enable VirtWifi on ethernet interface `eth0`. |

# Required patches for AOSP

| Repository | Commit message | Link |
| ---------- | -------------- | ---- |
| external/gptfdisk | gptfdisk: Build lib for recovery | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/368276) |
| external/gptfdisk | sgdisk: Make sgdisk recovery_available | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/368280) |
| system/core | init: devices: Add option to accept any device as boot device | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_system_core/+/378562) |

| Topic | Link |
| ----- | ---- |
| 14-embed-super_empty_img | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-embed-super_empty_img%22) |
| 14-recovery-ethernet | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-recovery-ethernet%22) |

# Build

The device tree targets Android 13 QPR3.

1. Initialize build environment

```
source build/envsetup.sh
```

2. Select the build target (Using `virtio_x86_64` as example)

For AOSP:
`lunch aosp_virtio_x86_64-ap2a-userdebug`

For LineageOS:
`breakfast virtio_x86_64`

3. Build

To build vda disk image:
`make diskimage-vda`

To build EFI System Partition (Boot) image:
`make espimage-boot`

To build EFI System Partition (Install) image:
`make espimage-install`
