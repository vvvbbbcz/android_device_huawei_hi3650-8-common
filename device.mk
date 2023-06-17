#
# Copyright (C) 2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Recovery
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.hi3650.rc:$(TARGET_RECOVERY_OUT)/root/init.recovery.hi3650.rc

# Rootdir
PRODUCT_PACKAGES += \
    fstab.hi3650 \
    fstab.hi3650.ramdisk \
    init.connectivity.rc \
    init.extmodem.rc \
    init.hi3650.rc \
    init.hisi.rc \
    init.hisi.usb.rc \
    init.platform.rc \
    init.tee.rc \
    ueventd.hi3650.rc

# Shipping API level
PRODUCT_SHIPPING_API_LEVEL := 27

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/hisi

# Inherit the proprietary files
$(call inherit-product, vendor/huawei/next/next-vendor.mk)
