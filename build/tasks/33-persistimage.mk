#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

##### persistimage #####

$(INSTALLED_PERSISTIMAGE_TARGET): $(INSTALLED_PERSISTIMAGE_TARGET_DEPS)
	$(hide) mkdir -p $(dir $@)
	$(call create-fat32image,$@,$(INSTALLED_PERSISTIMAGE_TARGET_DEPS),persist,16)

.PHONY: persistimage
persistimage: $(INSTALLED_PERSISTIMAGE_TARGET)

$(INSTALLED_RECOVERY_PERSISTIMAGE_GZ_TARGET): $(INSTALLED_PERSISTIMAGE_TARGET)
	cat $(INSTALLED_PERSISTIMAGE_TARGET) | gzip > $@

endif # USES_DEVICE_VIRT_VIRT_COMMON
