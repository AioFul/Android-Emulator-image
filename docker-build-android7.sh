#!/bin/bash

# Build Android 7.1 x86 version
docker build \
    --build-arg ARCH="x86" \
    --build-arg TARGET="google_apis" \
    --build-arg API_LEVEL="25" \
    --build-arg BUILD_TOOLS="25.0.3" \
    --build-arg EMULATOR_NAME="nexus" \
    --build-arg EMULATOR_DEVICE="Nexus_5" \
    -t android7-emulator-nexus:api25 .

# Build Android 7.1 ARM version
docker build \
    --build-arg ARCH="arm64-v8a" \
    --build-arg TARGET="google_apis" \
    --build-arg API_LEVEL="25" \
    --build-arg BUILD_TOOLS="25.0.3" \
    --build-arg EMULATOR_NAME="nexus" \
    --build-arg EMULATOR_DEVICE="Nexus_5" \
    -t android7-emulator-nexus:api25-arm .

# Run with VNC
docker run -it --privileged \
    -p 5901:5900 \
    -p 6081:6080 \
    -p 4726:4723 \
    -e EMULATOR_MEMORY=1024 \
    -e EMU_GPU="-gpu swiftshader_indirect" \
    -e EMU_ACCEL="-accel off" \
    -e EMU_LOW_RAM="-lowram" \
    -v ./volumes/avd7:/root/.android/avd \
    --name android7Container \
    android7-emulator-nexus:api25 \
    bash -c "./scripts/start_vnc.sh"
