/*
 * Copyright (C) 2021 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_utils.h>
#include <libinit_variant.h>

#include <unistd.h>

void set_variant_props(const variant_info_t variant) {
    // Older devices don't have marketname
    auto marketname = !variant.marketname.empty() ? variant.marketname : variant.model;

    set_ro_build_prop("brand", variant.brand, true);
    set_ro_build_prop("device", variant.device, true);
    set_ro_build_prop("marketname", marketname, true);
    set_ro_build_prop("model", variant.model, true);

    if (access("/system/bin/recovery", F_OK) != 0) {
        property_override("bluetooth.device.default_name", marketname, true);
        set_ro_build_prop("fingerprint", variant.build_fingerprint);
        property_override("ro.bootimage.build.fingerprint", variant.build_fingerprint);

        property_override("ro.build.description", fingerprint_to_description(variant.build_fingerprint));
    }
}
