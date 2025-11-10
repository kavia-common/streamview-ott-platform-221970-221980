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

# Detect if running inside our container image where app is at /app
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == "/app"* ]]; then
  APP_ROOT="/app"
else
  APP_ROOT="$SCRIPT_DIR"
fi

# Build directory resolution:
# Priority order:
# 1) Respect explicit BUILD_DIR env var if provided (non-empty)
# 2) If inside container at /app, default to /app/build (stable path expected by orchestration)
# 3) Otherwise default to $APP_ROOT/build for local runs
if [[ -n "${BUILD_DIR:-}" ]]; then
  BUILD_DIR="$BUILD_DIR"
elif [[ "$APP_ROOT" == "/app" ]]; then
  BUILD_DIR="/app/build"
else
  BUILD_DIR="$APP_ROOT/build"
fi

CMAKE_SOURCE_DIR="$APP_ROOT"

log "APP_ROOT=$APP_ROOT"
log "BUILD_DIR=$BUILD_DIR"

# Ensure build directory exists.
mkdir -p "$BUILD_DIR"

# Backward compatibility: ensure /tv_ott_native_app/build points to the active build dir when in container.
if [[ "$APP_ROOT" == "/app" ]]; then
  # Always ensure compatibility path exists
  if [[ ! -e "/tv_ott_native_app" ]]; then
    mkdir -p /tv_ott_native_app
  fi
  # If /tv_ott_native_app/build does not exist, create a symlink to BUILD_DIR (usually /app/build)
  if [[ ! -e "/tv_ott_native_app/build" ]]; then
    ln -s "$BUILD_DIR" /tv_ott_native_app/build
    log "Created symlink: /tv_ott_native_app/build -> $BUILD_DIR"
  else
    # If it exists but is a directory and different from BUILD_DIR, keep both (do not remove).
    if [[ -d "/tv_ott_native_app/build" && "/tv_ott_native_app/build" != "$BUILD_DIR" ]]; then
      log "Note: /tv_ott_native_app/build exists as directory; keeping both paths."
    fi
  fi
fi

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
