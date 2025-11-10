#!/usr/bin/env bash
# entrypoint.sh - Robust startup script for tv_ott_native_app container.
# Purpose: Configure, build, and run the Qt6 CMake application reliably.
# Avoids common bash -c multiline and CRLF pitfalls that can trigger:
#   bash: -c: line 2: syntax error: unexpected end of file

# Fail fast and safely on errors, unset vars, and failed pipes.
set -euo pipefail

# Normalize IFS to avoid weird parsing issues in loops/reads.
IFS=$' \t\n'

# Basic logging function.
log() { printf '[tv_ott_native_app] %s\n' "$*"; }

# Self-check for CRLF line endings (should not occur in image).
if LC_ALL=C grep -q $'\r' "$0"; then
  log "Warning: Detected CRLF line endings in entrypoint; attempting to run regardless."
fi

# Workspace and build directories.
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$APP_ROOT/.." && pwd)"
PROJECT_ROOT="$WORKSPACE_ROOT"
CMAKE_SOURCE_DIR="$APP_ROOT"
BUILD_DIR="${BUILD_DIR:-$APP_ROOT/build}"

log "APP_ROOT=$APP_ROOT"
log "BUILD_DIR=$BUILD_DIR"

# Ensure build directory exists.
mkdir -p "$BUILD_DIR"

# Configure and build (Qt6 app). If Docker image lacks Qt6, this will fail in CI and should be addressed there.
if [ ! -f "$BUILD_DIR/Makefile" ]; then
  log "Configuring project with CMake..."
  cmake -S "$CMAKE_SOURCE_DIR" -B "$BUILD_DIR"
fi

log "Building project..."
CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
cmake --build "$BUILD_DIR" -- -j"$CORES"

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
