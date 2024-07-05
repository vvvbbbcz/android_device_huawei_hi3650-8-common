#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=eva
VENDOR=huawei

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi

source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/etc/camera/*|odm/etc/camera/*)
	    sed -i 's/gb2312/iso-8859-1/g' "${2}"
	    sed -i 's/GB2312/iso-8859-1/g' "${2}"
	    sed -i 's/xmlversion/xml version/g' "${2}"
            ;;
        vendor/etc/init/android.hardware.drm@1.0-service.widevine.rc)
            sed -i 's/preavs/vendor/g' "${2}"
            ;;
        lib64/libemcomutil.so)
            "${PATCHELF}" --add-needed "libshim_emcom.so" "${2}"
            ;;
        vendor/lib*/egl/libGLES_mali.so|vendor/lib*/hw/gralloc.hi3650.so)
            "${PATCHELF}" --add-needed "libutilscallstack.so" "${2}"
            ;;
        vendor/lib64/hw/android.hardware.camera.provider@2.4-impl-hisi.so|vendor/lib64/camera.device@*-impl-v27.so)
            "${PATCHELF}" --replace-needed "camera.device@1.0-impl.so" "camera.device@1.0-impl-v27.so" "${2}"
            "${PATCHELF}" --replace-needed "camera.device@3.2-impl.so" "camera.device@3.2-impl-v27.so" "${2}"
            ;;
        vendor/lib*/hw/camera.hi3650.so)
            "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            ;;
        vendor/lib*/mediadrm/libwvdrmengine.so)
            "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
            ;;
        vendor/lib*/libwvhidl.so)
            "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
            ;;
        vendor/lib*/libcamera_algo.so)
            sed -i 's|libgui.so|guivnd.so|g' "${2}"
            "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            "${PATCHELF}" --replace-needed "libsensor.so" "libsensor_vendor.so" "${2}"
            ;;
        vendor/lib*/libcamera_ivp.so)
            sed -i 's|libgui.so|guivnd.so|g' "${2}"
            "${PATCHELF}" --add-needed "libui_shim.so" "${2}"
            ;;
        vendor/lib64/libskia.so)
            "${PATCHELF}" --add-needed "libpiex_shim.so" "${2}"
            ;;
        vendor/lib*/libHWCamCfgSvr.so)
            "${PATCHELF}" --add-needed "libbinder_shim.so" "${2}"
            ;;
        vendor/lib64/libFaceBeautyMeiwo*.so|vendor/lib64/libcontrastCal.so)
            sed -i 's|libgui.so|guivnd.so|g' "${2}"
            ;;
        vendor/lib64/hw/keystore.hi3650.so)
            sed -i 's|/system/lib64/libcrypto.so|libcrypto.so\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g' "${2}"
            ;;
        vendor/lib*/hw/vendor.huawei.hardware.hisupl@1.0-impl.so)
            # Respect the HMI's ID, which is hisupl
            sed -i 's|hisupl.hi1102|hisupl\x00\x00\x00\x00\x00\x00\x00|g' "${2}"
            ;;
        vendor/lib*/hw/vendor.huawei.hardware.gnss@1.0-impl.so)
            # Respect the HMI's ID, which is gps/flp
            sed -i 's|gps47531|gps\x00\x00\x00\x00\x00|g' "${2}"
            sed -i 's|flp4774|flp\x00\x00\x00\x00|g' "${2}"
            ;;
        vendor/lib*/libiawareperf_server.so)
            "${PATCHELF}" --add-needed "libtinyxml2_shim.so" "${2}"
            ;;
        vendor/lib*/libperfhub_service.so)
            "${PATCHELF}" --add-needed "libtinyxml2_shim.so" "${2}"
            ;;
        vendor/lib*/libRefocusContrastPosition.so)
            patchelf --add-needed "libshim_log.so" "${2}"
            ;;
        vendor/lib*/libhwlog.so)
            "${PATCHELF}" --add-needed "libshim_log.so" "${2}"
            ;;
        vendor/lib*/soundfx/libhuaweiprocessing.so)
            "${PATCHELF}" --remove-needed "libicuuc.so" "${2}"
            ;;
        vendor/lib*/hw/flp.default.so)
            "${PATCHELF}" --remove-needed "libicuuc.so" "${2}"
            "${PATCHELF}" --add-needed "libutils_shim.so" "${2}"
            ;;
        vendor/lib*/hw/audio.primary_hisi.hi3650.so|vendor/lib*/libhivwservice.so)
	    "${PATCHELF}" --add-needed "libprocessgroup.so" "${2}"
	    ;;
        vendor/lib64/hw/hwcomposer.hi3650.so)
            "${PATCHELF}" --replace-needed "libui.so" "libui-v28.so" "${2}"
            ;;
        vendor/bin/CameraDaemon)
            "${PATCHELF}" --add-needed "libbinder_shim.so" "${2}"
            ;;
        vendor/bin/modemlogcat_lte)
            "${PATCHELF}" --add-needed "libshim_utils.so" "${2}"
            ;;
        vendor/bin/system_teecd|vendor/bin/teecd)
            "${SIGSCAN}" -p "1f 05 00 71 41 03 00 54" -P "1f 05 00 71 1a 00 00 14" -f "${2}"
            ;;
        vendor/bin/gpsdaemon)
            "${PATCHELF}" --replace-needed "libicuuc.so" "libicuuc-v27.so" "${2}"
            ;;
        vendor/bin/glgps*)
            sed -i "s/SSLv3_client_method/SSLv23_method\x00\x00\x00\x00\x00\x00/" "${2}"
            ;;
        vendor/bin/hw/android.hardware.drm@1.0-service.widevine)
            "${PATCHELF}" --add-needed "libbase_shim.so" "${2}"
            ;;
        vendor/lib*/vendor.huawei.hardware.graphics.gpucommon@1.0.so)
            "${PATCHELF}" --add-needed "android.hardware.graphics.common@1.0_types.so" "${2}"
            ;;
        vendor/lib*/vendor.huawei.hardware.fusd@1.1.so)
            "${PATCHELF}" --add-needed "android.hardware.gnss@1.0_types" "${2}"
            ;;
        vendor/lib*/hw/vendor.huawei.hardware.sensors@1.0-impl.so)
            "${PATCHELF}" --add-needed "libbase_shim.so" "${2}"
            ;;
        vendor/lib*/vendor.huawei.hardware.radio@1.0.so)
            "${PATCHELF}" --add-needed "android.hardware.radio@1.0_types.so" "${2}"
            ;;
    esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../../${VENDOR}/${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"
    extract "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
