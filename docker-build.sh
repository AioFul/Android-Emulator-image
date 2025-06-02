docker build \
    --build-arg ARCH="x86" \
    --build-arg TARGET="google_apis" \
    --build-arg API_LEVEL="28" \
    --build-arg BUILD_TOOLS="28.0.3" \
    --build-arg EMULATOR_NAME="pixel" \
    --build-arg EMULATOR_DEVICE="pixel_3a" \
    -t android-emulator-pixel:api28 .

# 如需构建其它架构/设备/系统，可通过--build-arg覆盖上述参数
docker build \
    --build-arg ARCH="arm64-v8a" \
    --build-arg TARGET="google_apis" \
    --build-arg API_LEVEL="28" \
    --build-arg BUILD_TOOLS="28.0.3" \
    --build-arg EMULATOR_NAME="pixel" \
    --build-arg EMULATOR_DEVICE="pixel_3a" \
    -t android-emulator-pixel:api28 .


docker run -it --privileged \
    -p 5900:5900 \
    -p 6080:6080 \
    -p 4723:4723 \
    -v ./volumes/avd:/root/.android/avd \
    --name androidContainer \
    android-emulator-pixel:api28 \
    bash -c "./scripts/start_vnc.sh"