# Android Emulator Docker Image

本项目提供了一个高度灵活、可多开的 Android 模拟器 Docker 镜像，支持 Appium 自动化、VNC/noVNC 可视化、快照加速等特性，适合在有限资源服务器上高效运行多个模拟器实例。

## 特性

- 支持 Headless（无界面）与 Headed（VNC/GUI）两种模式
- 集成 Appium，适合自动化测试
- 支持快照（Snapshot），大幅提升冷启动和多开效率
- 默认参数已针对多开和资源节省优化
- 脚本集中于 `/scripts` 目录，便于维护和热替换

## 快速开始

### 构建镜像

```bash
docker build \
    --build-arg ARCH=x86 \
    --build-arg TARGET=google_apis \
    --build-arg API_LEVEL=28 \
    --build-arg BUILD_TOOLS=28.0.3 \
    --build-arg EMULATOR_NAME=pixel \
    --build-arg EMULATOR_DEVICE=pixel_3a \
    -t android-emulator:api28 .
```

### 启动容器（示例）

```bash
docker run -it --privileged -d \
    -p 5900:5900 -p 6080:6080 -p 4723:4723 \
    --name androidContainer \
    android-emulator:api28
```

### 启动 Headless 模拟器（推荐多开）

```bash
docker exec -it androidContainer bash -c "/scripts/start_emu_headless.sh"
```

### 启动带界面模拟器（VNC）

```bash
docker exec -it androidContainer bash -c "/scripts/start_vnc.sh"
# 然后在VNC客户端连接5900端口，终端执行 /scripts/start_emu.sh
```

### 启动 Appium

```bash
docker exec -it androidContainer bash -c "/scripts/start_appium.sh"
```

## 多开与资源优化建议

- **快照支持**：已默认开启快照（未加 -no-snapshot），首次启动后后续启动极快，适合多开。
- **内存**：建议 `EMU_MEMORY=512`，资源紧张时可更低。
- **分辨率/DPI**：`EMU_SKIN=480x800`，`EMU_DPI=120`，小屏低DPI更省资源。
- **CPU核数**：`EMU_SMP=1`，每个模拟器只用1核。
- **禁用音频/摄像头/GPU**：`-noaudio -camera-back none -gpu swiftshader_indirect`。
- **硬件加速**：`-accel off`，无KVM时避免模拟器尝试硬件加速。
- **磁盘缓存**：`-nocache`，减少I/O压力。
- **超时时间**：`EMULATOR_TIMEOUT=300` 或更高，资源紧张时模拟器启动慢。

## 主要参数说明

| 变量名              | 作用说明                   | 推荐默认值      | 说明                         |
|---------------------|----------------------------|----------------|------------------------------|
| EMULATOR_NAME       | AVD 名称                   | pixel          | 可通过环境变量覆盖           |
| EMULATOR_DEVICE     | 设备型号                   | pixel_3a       | 可通过环境变量覆盖           |
| ARCH                | 架构                       | x86            | 推荐x86，资源占用低          |
| API_LEVEL           | Android API级别            | 28             | Android 9，兼容性好          |
| EMU_MEMORY          | 分配内存（MB）             | 512            | 多开建议512                  |
| EMU_SKIN            | 屏幕分辨率                 | 480x800        | 小屏省资源                   |
| EMU_DPI             | 屏幕DPI                    | 120            | 低DPI省资源                  |
| EMU_SMP             | CPU核数                    | 1              | 多开建议1                    |
| EMU_NOAUDIO         | 禁用音频                   | -noaudio       | 禁用音频                     |
| EMU_NOCACHE         | 禁用磁盘缓存               | -nocache       | 禁用磁盘缓存                 |
| EMU_NO_WINDOW       | 无窗口（headless）         | -no-window     | headless模式用               |
| EMU_CAMERA_BACK     | 后置摄像头                 | -camera-back none | 禁用摄像头                |
| EMU_GPU             | GPU加速                    | -gpu swiftshader_indirect       | 使用 SwiftShader 进行软件渲染，提升兼容性                      |
| EMU_ACCEL           | 硬件加速                   | -accel off     | 无KVM建议-off                |
| EMULATOR_TIMEOUT    | 启动超时时间（秒）         | 300            | 资源紧张可适当调高           |

## 环境变量与脚本

所有启动脚本均位于 `/scripts` 目录，支持通过 `-v` 绑定热替换。

- `/scripts/start_emu_headless.sh`：无界面多开推荐
- `/scripts/start_emu.sh`：带窗口（VNC）模式
- `/scripts/start_vnc.sh`：启动VNC/noVNC服务
- `/scripts/start_appium.sh`：启动Appium服务

## Docker Compose 示例

```yaml
services:
  android-service:
    image: android-emulator
    build:
      context: .
      args:
        ARCH: "x86"
        API_LEVEL: "28"
        BUILD_TOOLS: "28.0.3"
        EMULATOR_DEVICE: "pixel_3a"
        EMULATOR_NAME: "pixel"
    ports:
      - 4725:4725
    container_name: android
    environment:
      - APPIUM_PORT=4725
      # 可添加更多环境变量覆盖参数
    privileged: true
    command:
      - bash
      - -c
      - |
         /scripts/start_emu_headless.sh
    tty: true
    stdin_open: true
```

## 常见问题

- **如何多开？**  
  启动多个容器或在单容器内多次运行 `/scripts/start_emu_headless.sh`，建议每个模拟器分配最小资源。
- **快照为何重要？**  
  快照可极大提升模拟器冷启动速度，适合批量自动化和多开场景。
- **如何自定义脚本？**  
  可通过 `-v /your/scripts:/scripts` 绑定自定义脚本目录。

---

如需进一步定制或有其它问题，欢迎反馈！
