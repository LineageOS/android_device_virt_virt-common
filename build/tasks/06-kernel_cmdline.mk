#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

INSTALLED_GRUB_KERNEL_CMDLINE_CFG_TARGET := $(PRODUCT_OUT)/.grub_kernel_cmdline.cfg

$(INSTALLED_GRUB_KERNEL_CMDLINE_CFG_TARGET):
	rm -f $@
	echo "set kernel_cmdline_boot=\"$(strip $(BOARD_KERNEL_CMDLINE) $(BOARD_KERNEL_CMDLINE_BOOT))\"" >> $@
	echo "set kernel_cmdline_recovery=\"$(strip $(BOARD_KERNEL_CMDLINE) $(BOARD_KERNEL_CMDLINE_RECOVERY))\"" >> $@
	echo "export kernel_cmdline_boot kernel_cmdline_recovery" >> $@

endif # USES_DEVICE_VIRT_VIRT_COMMON
