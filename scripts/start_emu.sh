#!/bin/bash
# export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export ANDROID_EMULATOR_DISABLE_WARNING=1

BL='\033[0;34m'
G='\033[0;32m'
RED='\033[0;31m'
YE='\033[1;33m'
NC='\033[0m' # No Color

# 以下5个参数已在Dockerfile中设置默认值，无需在此重复赋值
EMULATOR_NAME=${EMULATOR_NAME}
EMULATOR_DEVICE=${EMULATOR_DEVICE}
ARCH=${ARCH}
API_LEVEL=${API_LEVEL}
EMU_MEMORY=${EMULATOR_MEMORY}

EMU_SKIN=${EMULATOR_SKIN:-480x800}
EMU_DPI=${EMULATOR_DPI:-120}
EMU_SMP=${EMULATOR_SMP:-1}
EMU_NOAUDIO=${EMULATOR_NOAUDIO:-"-noaudio"}
EMU_NOCACHE=${EMULATOR_NOCACHE:-"-nocache"}
EMU_NO_SNAPSHOT=${EMULATOR_NO_SNAPSHOT:-""} # -no-snapshot
EMU_NO_WINDOW=${EMULATOR_NO_WINDOW:-""} # headed模式默认有窗口
EMU_CAMERA_BACK=${EMULATOR_CAMERA_BACK:-"-camera-back none"}
EMU_CAMERA_FRONT=${EMULATOR_CAMERA_FRONT:-"-camera-front none"}
EMU_GPU=${EMULATOR_GPU:-"-gpu swiftshader_indirect"}
EMU_ACCEL=${EMULATOR_ACCEL:-"-accel off"}
EMU_LOW_RAM=${EMULATOR_LOW_RAM:-"-lowram"}
EMU_NO_METRICS=${EMULATOR_NO_METRICS:-"-no-metrics"}

function wait_emulator_to_be_ready() {
  args=(
    -avd "${EMULATOR_NAME}"
    ${EMU_ACCEL}
    -memory ${EMU_MEMORY}
    -skin ${EMU_SKIN}
    -cores ${EMU_SMP}
    -no-boot-anim
    # -wipe-data
    ${EMU_GPU}
    ${EMU_NOAUDIO}
    ${EMU_NOCACHE}
    ${EMU_CAMERA_BACK}
    ${EMU_CAMERA_FRONT}
    ${EMU_LOW_RAM}
    ${EMU_NO_METRICS}
  )
  # 只在有值时追加参数
  [ -n "${EMU_NO_SNAPSHOT}" ] && args+=(${EMU_NO_SNAPSHOT})
  [ -n "${EMU_NO_WINDOW}" ] && args+=(${EMU_NO_WINDOW})

  echo "ARGS:" "${args[@]}"
  emulator "${args[@]}"
  printf "${G}==>  ${BL}Emulator has ${YE}${EMULATOR_NAME} ${BL}started! ${G}<==${NC}\n"
}

function disable_animation() {
  adb shell "settings put global window_animation_scale 0.0"
  adb shell "settings put global transition_animation_scale 0.0"
  adb shell "settings put global animator_duration_scale 0.0"
  adb shell "settings put global anr_show_background 0"
  adb shell "settings put global anr_timeout 60000"
}

wait_emulator_to_be_ready
sleep 1
disable_animation