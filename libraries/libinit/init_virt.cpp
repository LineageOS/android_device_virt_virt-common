/*
 * Copyright (C) 2025 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_variant.h>
#include <libinit_virt.h>

#include <unistd.h>

#include "vendor_init.h"

static const variant_info_t spoof_info = {
#if defined(__x86_64__)
    .brand = "google",
    .device = "generic",
    .manufacturer = "Google",
    .model = "mainline",
    .name = "mainline",
    .build_fingerprint = "google/gsi_gms_x86_64/generic_x86_64:15/AP4A.241205.013/12621605:user/release-keys",
    .security_patch = "2024-12-05",
#else
    .brand = "xiaomi",
    .device = "ugg",
    .manufacturer = "Xiaomi",
    .model = "Redmi Note 5A",
    .name = "ugg",
    .build_fingerprint = "xiaomi/ugg/ugg:7.1.2/N2G47H/V11.0.2.0.NDKMIXM:user/release-keys",
    .security_patch = "2019-08-01",
#endif
};

void vendor_load_properties() {
    vendor_load_properties_virt();
    if (access("/product/etc/sysconfig/google.xml", F_OK) == 0) {
        set_variant_props(spoof_info);
    }
}
