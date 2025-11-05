/*
 * Copyright (C) 2025 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/file.h>
#include <android-base/properties.h>
#include <sys/sysinfo.h>

#include <libinit_dalvik_heap.h>
#include <libinit_set_properties.h>
#include <libinit_utils.h>
#include <libinit_virt.h>

#include <unordered_map>

#define GB(b) (b * 1024ull * 1024 * 1024)

using android::base::GetProperty;

static void set_misc_properties() {
    struct sysinfo sys;
    sysinfo(&sys);

    if (sys.totalram >= GB(2)) {
        if (GetProperty("ro.boot.graphics", "") != "swiftshader" &&
            GetProperty("ro.boot.low_perf", "") != "1") {
            property_override("ro.surface_flinger.supports_background_blur", "1");
        }
    }

    if (GetProperty("ro.boot.insecure_adb", "") == "1") {
        property_override("ro.adb.secure", "0");
        property_override("ro.secure", "0");
    }
}

void vendor_load_properties_virt() {
    set_dalvik_heap();
    set_misc_properties();
    set_properties_from_dmi_id();
}
