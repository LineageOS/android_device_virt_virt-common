#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

ifneq ($(TARGET_BOOT_MANAGER),)

##### espimage #####

$(INSTALLED_ESPIMAGE_TARGET): $(INSTALLED_ESPIMAGE_TARGET_DEPS)
	$(hide) mkdir -p $(dir $@)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_INCLUDE_FILES))

.PHONY: espimage
espimage: $(INSTALLED_ESPIMAGE_TARGET)

.PHONY: espimage-nodeps
espimage-nodeps:
	@echo "make $(INSTALLED_ESPIMAGE_TARGET): ignoring dependencies"
	$(hide) mkdir -p $(dir $@)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_INCLUDE_FILES))

##### espimage-install #####

$(INSTALLED_ESPIMAGE_INSTALL_TARGET): $(INSTALLED_ESPIMAGE_INSTALL_TARGET_DEPS)
	$(call make-espimage-install-target,$(INSTALLED_ESPIMAGE_INSTALL_TARGET),$(INSTALLED_ESPIMAGE_INSTALL_TARGET_INCLUDE_FILES))

.PHONY: espimage-install
espimage-install: $(INSTALLED_ESPIMAGE_INSTALL_TARGET)

.PHONY: espimage-install-nodeps
espimage-install-nodeps:
	@echo "make $(INSTALLED_ESPIMAGE_INSTALL_TARGET): ignoring dependencies"
	$(call make-espimage-install-target,$(INSTALLED_ESPIMAGE_INSTALL_TARGET),$(INSTALLED_ESPIMAGE_INSTALL_TARGET_INCLUDE_FILES))

endif # TARGET_BOOT_MANAGER

endif # USES_DEVICE_VIRT_VIRT_COMMON
