#!/bin/bash

readonly G_LOG_I='[INFO]'
readonly G_LOG_W='[WARN]'
readonly G_LOG_E='[ERROR]'
BL='\033[0;34m'
G='\033[0;32m'
NC='\033[0m' # No Color

main() {
    launch_xvfb
    launch_window_manager
    run_vnc_server
    run_novnc
    printf "${G}==> ${BL}Welcome to android-emulator VNC + noVNC by amrsa ${G}<==${NC}""\n"
    wait # 保持脚本前台运行（等待所有后台进程）
}

launch_xvfb() {
    export DISPLAY=${XVFB_DISPLAY:-:1}
    local screen=${XVFB_SCREEN:-0}
    local resolution=${XVFB_RESOLUTION:-1280x1024x24}
    local timeout=${XVFB_TIMEOUT:-5}

    Xvfb ${DISPLAY} -screen ${screen} ${resolution} &
    local loopCount=0
    until xdpyinfo -display ${DISPLAY} > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            echo "${G_LOG_E} xvfb failed to start."
            exit 1
        fi
    done
}

launch_window_manager() {
    local timeout=${XVFB_TIMEOUT:-5}

    fluxbox &
    local loopCount=0
    until wmctrl -m > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            echo "${G_LOG_E} fluxbox failed to start."
            exit 1
        fi
    done
}

run_vnc_server() {
    local passwordArgument='-nopw'

    if [ -n "${VNC_PASSWORD}" ]
    then
        local passwordFilePath="${HOME}/x11vnc.pass"
        if ! x11vnc -storepasswd "${VNC_PASSWORD}" "${passwordFilePath}"
        then
            echo "${G_LOG_E} Failed to store x11vnc password."
            exit 1
        fi
        passwordArgument="-rfbauth ${passwordFilePath}"
        echo "${G_LOG_I} The VNC server will ask for a password."
    else
        echo "${G_LOG_W} The VNC server will NOT ask for a password."
    fi

    # VNC服务器监听5900端口
    x11vnc -ncache_cr -display ${DISPLAY} -forever ${passwordArgument} -rfbport 5900 &
    export VNC_PID=$!
}

run_novnc() {
    local novnc_dir="/opt/novnc"
    local listen_port=6080
    local vnc_target="localhost:5900"

    if [ -x "${novnc_dir}/utils/novnc_proxy" ]; then
        echo "${G_LOG_I} Starting noVNC using novnc_proxy..."
        # --listen 默认6080, --vnc 指定VNC服务
        "${novnc_dir}/utils/novnc_proxy" --vnc "${vnc_target}" --listen "${listen_port}" &
        export NOVNC_PID=$!
        echo "${G_LOG_I} noVNC started on port ${listen_port} (http://localhost:${listen_port}/)"
    else
        echo "${G_LOG_E} novnc_proxy script not found in ${novnc_dir}/utils!"
        exit 1
    fi
}

control_c() {
    echo ""
    [ -n "$VNC_PID" ] && kill $VNC_PID
    [ -n "$NOVNC_PID" ] && kill $NOVNC_PID
    exit
}

trap control_c SIGINT SIGTERM SIGHUP

main

exit