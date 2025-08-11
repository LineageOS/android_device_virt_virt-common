# Android common device tree for Virtual Machines

```
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
```

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
| build/soong | androidmk_denylist: Allow external/mesa/android/Android.mk | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_build_soong/+/442534) |
| external/gptfdisk | gptfdisk: Build lib for recovery | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/433338) |
| external/gptfdisk | sgdisk: Make sgdisk recovery_available | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/433341) |
| system/core | init: devices: Add option to accept any device as boot device | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_system_core/+/433588) |

| Topic | Link |
| ----- | ---- |
| 14-recovery-ethernet | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-recovery-ethernet%22) |
