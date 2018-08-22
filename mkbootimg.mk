#
# Copyright (C) 2016 Android For Marvell Project <ctx.xda@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

MRVL_TOOLS_PATH := device/marvell/common/tools

MKBOOTIMG=$(MRVL_TOOLS_PATH)/mkbootimg

$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_FILES)
	$(call pretty,"Target boot image: $@")
	$(hide) $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_BOOTIMAGE_PARTITION_SIZE),raw)
	@echo -e ${CL_CYN}"Made boot image: $@"${CL_RST}

$(INSTALLED_RECOVERYIMAGE_TARGET): $(MKBOOTFS) $(MKBOOTIMG) $(MINIGZIP) \
		$(INSTALLED_RAMDISK_TARGET) \
		$(INSTALLED_BOOTIMAGE_TARGET) \
		$(recovery_binary) \
		$(recovery_initrc) $(recovery_kernel) \
		$(INSTALLED_2NDBOOTLOADER_TARGET) \
		$(recovery_build_prop) $(recovery_resource_deps) \
		$(recovery_fstab) \
		$(RECOVERY_INSTALL_OTA_KEYS)
	@echo ----- Making recovery image ------
	$(hide) rm -rf $(TARGET_RECOVERY_OUT)
	$(hide) mkdir -p $(TARGET_RECOVERY_OUT)
	$(hide) mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/etc $(TARGET_RECOVERY_ROOT_OUT)/tmp
	@echo Copying baseline ramdisk...
	$(hide) cp -R $(TARGET_ROOT_OUT) $(TARGET_RECOVERY_OUT)
	@echo Modifying ramdisk contents...
	$(hide) rm -f $(TARGET_RECOVERY_ROOT_OUT)/init*.rc
	$(hide) cp -f $(recovery_initrc) $(TARGET_RECOVERY_ROOT_OUT)/
	$(hide) -cp $(TARGET_ROOT_OUT)/init.recovery.*.rc $(TARGET_RECOVERY_ROOT_OUT)/
	$(hide) cp -f $(recovery_binary) $(TARGET_RECOVERY_ROOT_OUT)/sbin/
	$(hide) cp -rf $(recovery_resources_common) $(TARGET_RECOVERY_ROOT_OUT)/
	$(hide) cp -f $(recovery_font) $(TARGET_RECOVERY_ROOT_OUT)/res/images/font.png
	$(hide) $(foreach item,$(recovery_resources_private), \
	  cp -rf $(item) $(TARGET_RECOVERY_ROOT_OUT)/)
	$(hide) $(foreach item,$(recovery_fstab), \
	  cp -f $(item) $(TARGET_RECOVERY_ROOT_OUT)/etc/recovery.fstab)
	$(hide) cp $(RECOVERY_INSTALL_OTA_KEYS) $(TARGET_RECOVERY_ROOT_OUT)/res/keys
	$(hide) cat $(INSTALLED_DEFAULT_PROP_TARGET) $(recovery_build_prop) \
	        > $(TARGET_RECOVERY_ROOT_OUT)/default.prop
	$(hide) $(MKBOOTFS) $(TARGET_RECOVERY_ROOT_OUT) | $(MINIGZIP) > $(recovery_ramdisk)
	$(hide) $(MKBOOTIMG) $(INTERNAL_RECOVERYIMAGE_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE),raw)
	@echo ----- Made recovery image: $@ --------
