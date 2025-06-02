#!/bin/bash

BL='\033[0;34m'
G='\033[0;32m'
RED='\033[0;31m'
YE='\033[1;33m'
NC='\033[0m' # No Color

emulator_name=${EMULATOR_NAME}

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
EMU_NO_SNAPSHOT=${EMULATOR_NO_SNAPSHOT:-""}
EMU_NO_WINDOW=${EMULATOR_NO_WINDOW:--no-window}
EMU_CAMERA_BACK=${EMULATOR_CAMERA_BACK:-"-camera-back none"}
EMU_CAMERA_FRONT=${EMULATOR_CAMERA_FRONT:-"-camera-front none"}
EMU_GPU=${EMULATOR_GPU:-"-gpu swiftshader_indirect"}
EMU_ACCEL=${EMULATOR_ACCEL:-"-accel off"}
EMU_LOW_RAM=${EMULATOR_LOW_RAM:--lowram}
EMU_NO_METRICS=${EMULATOR_NO_METRICS:--no-metrics}

function check_hardware_acceleration() {
    if [[ "$HW_ACCEL_OVERRIDE" != "" ]]; then
        hw_accel_flag="$HW_ACCEL_OVERRIDE"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            HW_ACCEL_SUPPORT=$(sysctl -a | grep -E -c '(vmx|svm)')
        else
            HW_ACCEL_SUPPORT=$(grep -E -c '(vmx|svm)' /proc/cpuinfo)
        fi

        if [[ $HW_ACCEL_SUPPORT == 0 ]]; then
            hw_accel_flag="-accel off
        else
            hw_accel_flag="-accel on"
        fi
    fi

    echo "$hw_accel_flag"
}

hw_accel_flag=$(check_hardware_acceleration)

function launch_emulator () {
  adb devices | grep emulator | cut -f1 | xargs -I {} adb -s "{}" emu kill
  options="@${emulator_name} ${EMU_NO_WINDOW} -no-boot-anim -memory ${EMU_MEMORY} -skin ${EMU_SKIN} -dpi-device ${EMU_DPI} -cores ${EMU_SMP} ${hw_accel_flag} ${EMU_GPU} ${EMU_NOAUDIO} ${EMU_NOCACHE} ${EMU_NO_SNAPSHOT} ${EMU_CAMERA_BACK} ${EMU_CAMERA_FRONT} ${EMU_LOW_RAM} ${EMU_NO_METRICS}"
  if [[ "$OSTYPE" == *linux* ]]; then
    echo "${OSTYPE}: emulator ${options}"
    nohup emulator $options &
  fi
  if [[ "$OSTYPE" == *darwin* ]] || [[ "$OSTYPE" == *macos* ]]; then
    echo "${OSTYPE}: emulator ${options} -gpu swiftshader_indirect"
    nohup emulator $options -gpu swiftshader_indirect &
  fi

  if [ $? -ne 0 ]; then
    echo "Error launching emulator"
    return 1
  fi
}

function check_emulator_status () {
  printf "${G}==> ${BL}Checking emulator booting up status 🧐${NC}\n"
  start_time=$(date +%s)
  spinner=( "⠹" "⠺" "⠼" "⠶" "⠦" "⠧" "⠇" "⠏" )
  i=0
  timeout=${EMULATOR_TIMEOUT:-300}

  while true; do
    result=$(adb shell getprop sys.boot_completed 2>&1)

    if [ "$result" == "1" ]; then
      printf "\e[K${G}==> \u2713 Emulator is ready : '$result'           ${NC}\n"
      adb devices -l
      adb shell input keyevent 82
      break
    elif [ "$result" == "" ]; then
      printf "${YE}==> Emulator is partially Booted! 😕 ${spinner[$i]} ${NC}\r"
    else
      printf "${RED}==> $result, please wait ${spinner[$i]} ${NC}\r"
      i=$(( (i+1) % 8 ))
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ $elapsed_time -gt $timeout ]; then
      printf "${RED}==> Timeout after ${timeout} seconds elapsed 🕛.. ${NC}\n"
      break
    fi
    sleep 4
  done
};

function disable_animation() {
  adb shell "settings put global window_animation_scale 0.0"
  adb shell "settings put global transition_animation_scale 0.0"
  adb shell "settings put global animator_duration_scale 0.0"
};

function hidden_policy() {
  adb shell "settings put global hidden_api_policy_pre_p_apps 1;settings put global hidden_api_policy_p_apps 1;settings put global hidden_api_policy 1"
};

launch_emulator
sleep 2
check_emulator_status
sleep 1
disable_animation
sleep 1
hidden_policy
sleep 1