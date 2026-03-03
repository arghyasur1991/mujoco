# MuJoCo Build Scripts

## Android Cross-Compilation

Build `libmujoco.so` for Android arm64-v8a:

```bash
./scripts/build_android.sh
```

### Prerequisites

- **Android NDK** — either:
  - Set `ANDROID_NDK_HOME` environment variable, or
  - Install Android Build Support via Unity Hub (NDK auto-detected)
- **CMake** 3.22+

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ANDROID_NDK_HOME` | Auto-detect from Unity Hub | Path to Android NDK |
| `ANDROID_ABI` | `arm64-v8a` | Target ABI |
| `ANDROID_PLATFORM` | `android-32` | Minimum Android API level |
| `BUILD_DIR` | `build/android_arm64` | Build output directory |

### Output

The built `libmujoco.so` is deployed to `unity/Plugins/Android/arm64-v8a/`.

## macOS

On macOS, `libmujoco.dylib` comes from `pip install mujoco` — no build needed.
The official MuJoCo Unity plugin loads it automatically.
