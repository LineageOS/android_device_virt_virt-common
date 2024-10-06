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

# List of optional extra boot parameters

| Parameter | Possible values | Description |
| --------- | --------------- | ----------- |
| `androidboot.graphics` | `mesa`, `mesa_swrast` or `swiftshader` | Graphics stack to use. Default is `mesa`. |
| `androidboot.hwui_renderer` | `skiagl` or `skiavk` | HWUI renderer to use. Default is `skiagl`. |
| `androidboot.insecure_adb` | `1` | Add this to disable ADB authentication and enable ADB root. |
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
| 14-recovery-ethernet | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-recovery-ethernet%22) |
