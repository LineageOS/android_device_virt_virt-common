#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

# Super image (empty)
LPFLASH := $(HOST_OUT_EXECUTABLES)/lpflash$(HOST_EXECUTABLE_SUFFIX)
$(INSTALLED_RECOVERY_SUPERIMAGE_EMPTY_RAW_TARGET): $(LPFLASH) $(PRODUCT_OUT)/super_empty.img
	touch $@
	$(LPFLASH) $$(realpath $@) $(PRODUCT_OUT)/super_empty.img

endif # USES_DEVICE_VIRT_VIRT_COMMON
