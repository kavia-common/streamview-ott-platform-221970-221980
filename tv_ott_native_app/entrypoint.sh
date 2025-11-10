#!/usr/bin/env bash
# entrypoint.sh - Robust startup script for tv_ott_native_app container
# Ensures proper line endings, logs, and safe execution to avoid "bash: -c: line 2: syntax error: unexpected end of file"

set -euo pipefail

# Normalize IFS to avoid weird parsing
IFS=$' \t\n'

# Basic logging
log() { printf '[tv_ott_native_app] %s\n' "$*"; }

# Detect CRLF issues in this script (should never happen, but log if present)
if LC_ALL=C grep -q $'\r' "$0"; then
  log "Warning: Detected CRLF line endings in entrypoint; attempting to run regardless."
fi

# Workspace and build directories
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$APP_ROOT/.." && pwd)"
PROJECT_ROOT="$WORKSPACE_ROOT"
CMAKE_SOURCE_DIR="$APP_ROOT"
BUILD_DIR="${BUILD_DIR:-$APP_ROOT/build}"

log "APP_ROOT=$APP_ROOT"
log "BUILD_DIR=$BUILD_DIR"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Configure and build (Qt6 app). If Docker image lacks Qt6, this will fail in CI and should be addressed there.
if [ ! -f "$BUILD_DIR/Makefile" ]; then
  log "Configuring project with CMake..."
  cmake -S "$CMAKE_SOURCE_DIR" -B "$BUILD_DIR"
fi

log "Building project..."
cmake --build "$BUILD_DIR" -- -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"

# After build, the runtime output is configured to ${CMAKE_BINARY_DIR} (the build dir)
BIN_DIR="$BUILD_DIR"
BIN_PATH="$BIN_DIR/MainApp"

if [ ! -x "$BIN_PATH" ]; then
  # Sometimes CMake places executable differently; try to locate it
  CANDIDATE="$(find "$BUILD_DIR" -maxdepth 2 -type f -name 'MainApp' -perm -111 | head -n1 || true)"
  if [ -n "${CANDIDATE:-}" ]; then
    BIN_PATH="$CANDIDATE"
  fi
fi

if [ ! -x "$BIN_PATH" ]; then
  log "Error: Built binary not found or not executable at $BIN_PATH"
  ls -la "$BUILD_DIR" || true
  exit 1
fi

log "Starting MainApp..."
# Exec replaces shell to forward signals properly
exec "$BIN_PATH"
