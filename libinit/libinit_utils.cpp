/*
 * Copyright (C) 2021 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

#include <system_properties/system_properties.h>
#include <vector>

#include <libinit_utils.h>

static SystemProperties system_properties;

void property_override(std::string prop, std::string value, bool add) {
    auto pi = (prop_info *) system_properties.Find(prop.c_str());
    if (pi != nullptr) {
        system_properties.Update(pi, value.c_str(), value.length());
    } else if (add) {
        system_properties.Add(prop.c_str(), prop.length(), value.c_str(), value.length());
    }
}

std::vector<std::string> ro_props_default_source_order = {
    "odm.",
    "odm_dlkm.",
    "product.",
    "system.",
    "system_ext.",
    "vendor.",
    "vendor_dlkm.",
    "",
};

void set_ro_build_prop(const std::string &prop, const std::string &value, bool product) {
    std::string prop_name;

    for (const auto &source : ro_props_default_source_order) {
        if (product)
            prop_name = "ro.product." + source + prop;
        else
            prop_name = "ro." + source + "build." + prop;

        property_override(prop_name, value, true);
    }
}

bool libinit_systemproperties_init() {
//  bool fsetxattr_fail = false;
//  return system_properties.AreaInit(PROP_FILENAME, &fsetxattr_fail) && !fsetxattr_fail ? true : false;
    return system_properties.Init(PROP_FILENAME);
}
