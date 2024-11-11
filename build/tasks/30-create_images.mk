#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRT_COMMON),true)

# $(1): output file
# $(2): list of contents to include
# $(3): volume label
# $(4): image size in MB (optional)
define create-fat32image
	[ $(4) ] && [ $(4) -gt 0 ] && img_size=$(4) || \
		img_size=$$($(VIRT_COMMON_PATH)/bootmgr/.calc_fat32_img_size.sh $(2)); \
		/bin/dd if=/dev/zero of=$(1) bs=1M count=$$img_size
	$(BOOTMGR_TOOLS_BIN_DIR)/mformat -F -i $(1) -v "$(3)" ::
	$(foreach content,$(2),$(BOOTMGR_TOOLS_BIN_DIR)/mcopy -i $(1) -s $(content) :: &&)true
endef

endif # USES_DEVICE_VIRT_VIRT_COMMON
