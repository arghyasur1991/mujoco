#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUJOCO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$MUJOCO_ROOT/build/android_arm64}"
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-32}"

find_ndk() {
    if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "$ANDROID_NDK_HOME" ]; then
        echo "$ANDROID_NDK_HOME"
        return
    fi
    for editor_dir in /Applications/Unity/Hub/Editor/*/; do
        ndk="$editor_dir/PlaybackEngines/AndroidPlayer/NDK"
        if [ -d "$ndk" ]; then
            echo "$ndk"
            return
        fi
    done
    echo ""
}

NDK_HOME="${ANDROID_NDK_HOME:-$(find_ndk)}"
if [ -z "$NDK_HOME" ] || [ ! -d "$NDK_HOME" ]; then
    echo "ERROR: Android NDK not found."
    echo "  Set ANDROID_NDK_HOME or install Android Build Support via Unity Hub."
    exit 1
fi

NDK_TOOLCHAIN="$NDK_HOME/build/cmake/android.toolchain.cmake"
if [ ! -f "$NDK_TOOLCHAIN" ]; then
    echo "ERROR: NDK toolchain not found: $NDK_TOOLCHAIN"
    exit 1
fi

echo "=== Building libmujoco.so for Android $ANDROID_ABI ==="
echo "  NDK:      $NDK_HOME"
echo "  Source:    $MUJOCO_ROOT"
echo "  Build:     $BUILD_DIR"

mkdir -p "$BUILD_DIR"

cmake \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_TOOLCHAIN" \
    -DANDROID_ABI="$ANDROID_ABI" \
    -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
    -DCMAKE_BUILD_TYPE=Release \
    -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_TESTS=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF \
    -DMUJOCO_SAMPLES_USE_GLFW=OFF \
    -DMUJOCO_ENABLE_AVX_INTRINSICS=OFF \
    -DMUJOCO_ENABLE_RPATH=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -S "$MUJOCO_ROOT" \
    -B "$BUILD_DIR"

CPU_COUNT=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
cmake --build "$BUILD_DIR" --target mujoco -j"$CPU_COUNT"

LIBMUJOCO="$BUILD_DIR/lib/libmujoco.so"
if [ ! -f "$LIBMUJOCO" ]; then
    LIBMUJOCO=$(find "$BUILD_DIR" -name "libmujoco.so" | head -1)
fi

if [ ! -f "$LIBMUJOCO" ]; then
    echo "ERROR: libmujoco.so not found after build."
    exit 1
fi

DEPLOY_DIR="$MUJOCO_ROOT/unity/Plugins/Android/$ANDROID_ABI"
mkdir -p "$DEPLOY_DIR"
cp "$LIBMUJOCO" "$DEPLOY_DIR/libmujoco.so"

SIZE_KB=$(du -k "$DEPLOY_DIR/libmujoco.so" | cut -f1)
echo ""
echo "=== Done ==="
echo "  libmujoco.so (${SIZE_KB}KB) -> $DEPLOY_DIR/"
