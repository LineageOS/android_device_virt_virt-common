/*
 * Copyright (C) 2021 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <libinit_utils.h>
#include <libinit_variant.h>

#include <unistd.h>

void set_variant_props(const variant_info_t variant) {
    if (access("/system/bin/recovery", F_OK) == 0) return;

    set_ro_build_prop("brand", variant.brand, true);
    set_ro_build_prop("device", variant.device, true);
    set_ro_build_prop("manufacturer", variant.manufacturer, true);
    set_ro_build_prop("model", variant.model, true);
    set_ro_build_prop("name", variant.name, true);

    property_override("bluetooth.device.default_name", variant.model, true);
    set_ro_build_prop("fingerprint", variant.build_fingerprint);
    property_override("ro.bootimage.build.fingerprint", variant.build_fingerprint);

    property_override("ro.build.description", fingerprint_to_description(variant.build_fingerprint));

    if (!variant.security_patch.empty()) {
        property_override("ro.build.version.security_patch", variant.security_patch);
    }
}
