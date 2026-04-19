#!/bin/bash
set -euo pipefail

PROJECT="AwakeUtility.xcodeproj"
SCHEME="AwakeUtility"
CONFIG="Debug"

echo "[1/4] Building $SCHEME ($CONFIG)..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" build \
    2>&1 | tail -1

echo "[2/4] Finding build products..."
PRODUCTS_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
    -showBuildSettings 2>/dev/null \
    | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')

APP_PATH="$PRODUCTS_DIR/$SCHEME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: $APP_PATH not found"
    exit 1
fi

echo "  -> $APP_PATH"

echo "[3/4] Killing existing instance..."
pkill -f "AwakeUtility" 2>/dev/null || true
sleep 1

echo "[4/4] Launching..."
open "$APP_PATH"
sleep 1

if pgrep -q "AwakeUtility"; then
    echo "Done. AwakeUtility is running (PID $(pgrep AwakeUtility))"
else
    echo "WARNING: App may not have launched"
fi
