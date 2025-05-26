# ============================
# android-emulator Dockerfile
# 支持常用构建参数和运行时参数
# 常用运行时参数（docker run -e）：
#   VNC_PASSWORD        VNC密码，默认为空（无密码）
#   XVFB_DISPLAY       Xvfb display号，默认:1
#   XVFB_SCREEN        Xvfb屏幕号，默认0
#   XVFB_RESOLUTION    Xvfb分辨率，默认1280x1024x24
#   XVFB_TIMEOUT       Xvfb启动等待秒数，默认5
#   APPIUM_PORT        Appium服务端口，默认4723
#   ...（其它见ENV段）
# 常用构建参数（docker build --build-arg）：
#   API_LEVEL          Android API级别，默认34
#   BUILD_TOOLS        Build-tools版本，默认34.0.0
#   ARCH               cpu架构，默认x86_64
#   TARGET             system image类型，默认google_apis_playstore
#   EMULATOR_NAME      AVD名字，默认nexus
#   EMULATOR_DEVICE    设备名，默认Nexus 6
# ============================

# 1. Build Stage
FROM openjdk:18-jdk-slim AS builder

LABEL maintainer="Amr Salem"
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /

# ---- 基础运行/构建依赖 ----
RUN apt-get update && \
    apt-get install -y \
      curl sudo wget unzip bzip2 \
      libdrm-dev libxkbcommon-dev libgbm-dev libasound-dev libnss3 \
      libxcursor1 libpulse-dev libxshmfence-dev \
      xauth xvfb x11vnc fluxbox wmctrl libdbus-glib-1-2 \
      python3 python3-pip

# ---- 安装 noVNC ----
RUN mkdir -p /opt/novnc
RUN wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.6.0.tar.gz \
      | tar xz -C /opt/novnc --strip-components=1
RUN ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# ---- 安装 websockify ----
RUN wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.13.0.tar.gz \
      | tar xz -C /opt/novnc/utils && \
    mv /opt/novnc/utils/websockify-0.13.0 /opt/novnc/utils/websockify

# ---- Android SDK环境变量与构建参数 ----
ARG ARCH="x86_64"
ARG TARGET="google_apis_playstore"
ARG API_LEVEL="34"
ARG BUILD_TOOLS="34.0.0"
ARG ANDROID_API_LEVEL="android-${API_LEVEL}"
ARG ANDROID_APIS="${TARGET};${ARCH}"
ARG EMULATOR_PACKAGE="system-images;${ANDROID_API_LEVEL};${ANDROID_APIS}"
ARG PLATFORM_VERSION="platforms;${ANDROID_API_LEVEL}"
ARG BUILD_TOOL="build-tools;${BUILD_TOOLS}"
ARG ANDROID_CMD="commandlinetools-linux-11076708_latest.zip"
ARG ANDROID_SDK_PACKAGES="${EMULATOR_PACKAGE} ${PLATFORM_VERSION} ${BUILD_TOOL} platform-tools emulator"

ENV ANDROID_SDK_ROOT=/opt/android
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/${BUILD_TOOLS}"

# ---- 安装 Android Commandline Tools ----
RUN wget https://dl.google.com/android/repository/${ANDROID_CMD} -P /tmp
RUN unzip -d $ANDROID_SDK_ROOT /tmp/$ANDROID_CMD
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/tools
RUN cd $ANDROID_SDK_ROOT/cmdline-tools && \
    mv NOTICE.txt source.properties bin lib tools/
RUN cd $ANDROID_SDK_ROOT/cmdline-tools/tools && ls

# ---- 安装 SDK组件 ----
RUN yes Y | sdkmanager --licenses
RUN yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES}

# ---- 创建AVD ----
ARG EMULATOR_NAME="nexus"
ARG EMULATOR_DEVICE="Nexus 6"
ENV EMULATOR_NAME=$EMULATOR_NAME
ENV DEVICE_NAME=$EMULATOR_DEVICE
RUN echo "no" | avdmanager --verbose create avd --force \
    --name "${EMULATOR_NAME}" \
    --device "${EMULATOR_DEVICE}" \
    --package "${EMULATOR_PACKAGE}"

# ---- 拷贝脚本 ----
COPY . /
RUN chmod a+x start_vnc.sh start_emu.sh start_appium.sh start_emu_headless.sh





# ============================
# 2. Final Stage (Runtime)
# ============================
FROM openjdk:18-jdk-slim

LABEL maintainer="Amr Salem"
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /

# ---- 最小运行环境依赖 ----
RUN apt-get update && \
    apt-get install -y \
      curl sudo wget unzip bzip2 \
      libdrm-dev libxkbcommon-dev libgbm-dev libasound-dev libnss3 \
      libxcursor1 libpulse-dev libxshmfence-dev xauth xvfb x11vnc \
      fluxbox wmctrl libdbus-glib-1-2 python3 python3-pip procps && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- 安装 Node.js, npm, Appium（此处为运行时环境所需） ----
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash
RUN apt-get -qqy install nodejs
RUN npm install -g npm
RUN npm i -g appium --unsafe-perm=true --allow-root
RUN appium driver install uiautomator2
RUN npm cache clean --force
RUN apt-get remove --purge -y npm
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -Rf /tmp/* /var/lib/apt/lists/*

# ---- 复制build阶段产物 ----
COPY --from=builder /opt/android /opt/android
COPY --from=builder /root/.android /root/.android
COPY --from=builder /opt/novnc /opt/novnc
COPY --from=builder /usr/bin/x11vnc /usr/bin/x11vnc
COPY --from=builder /usr/bin/xvfb-run /usr/bin/xvfb-run
COPY --from=builder /usr/bin/Xvfb /usr/bin/Xvfb
COPY --from=builder /usr/bin/fluxbox /usr/bin/fluxbox
COPY --from=builder /usr/bin/wmctrl /usr/bin/wmctrl
COPY --from=builder /usr/bin/python3 /usr/bin/python3
COPY --from=builder /usr/bin/pip3 /usr/bin/pip3

# ---- 脚本 ----
COPY --from=builder /start_vnc.sh /
COPY --from=builder /start_emu.sh /
COPY --from=builder /start_appium.sh /
COPY --from=builder /start_emu_headless.sh /
RUN chmod a+x /start_vnc.sh /start_emu.sh /start_appium.sh /start_emu_headless.sh

# ---- 运行时可覆盖参数 ----
ENV ANDROID_SDK_ROOT=/opt/android
ENV XVFB_DISPLAY=:1
ENV XVFB_SCREEN=0
ENV XVFB_RESOLUTION=1280x1024x24
ENV XVFB_TIMEOUT=5
ENV VNC_PASSWORD="abcd.1234"
ENV DOCKER="true"
ENV EMU=./start_emu.sh
ENV EMU_HEADLESS=./start_emu_headless.sh
ENV VNC=./start_vnc.sh
ENV APPIUM=./start_appium.sh
ENV APPIUM_PORT=4723
ENV EMULATOR_NAME=nexus

# ---- 动态PATH，支持BUILD_TOOLS传递 ----
ARG BUILD_TOOLS="34.0.0"
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/${BUILD_TOOLS}"

# ---- 端口 ----
EXPOSE 5900 6080 4723

CMD ["/bin/bash"]