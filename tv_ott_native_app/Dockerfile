# Dockerfile for tv_ott_native_app
# Uses Ubuntu base, installs build tools and Qt6, builds app, and uses a robust entrypoint script.
# Guarantees both /app/build and /tv_ott_native_app/build exist at build-time and runtime.

FROM ubuntu:22.04

# Ensure non-interactive installs and safer shell defaults
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies: build tools, cmake, Qt6 Core and Widgets development packages
# Include tzdata to avoid edge-case interactive prompts on certain mirrors.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      tzdata \
      build-essential \
      cmake \
      qt6-base-dev \
      qt6-base-dev-tools \
      qt6-tools-dev \
      qt6-tools-dev-tools \
      libgl1 \
      libxcb-xinerama0 \
      libxkbcommon-x11-0 \
      libxrender1 \
      libxext6 \
      libx11-xcb1 \
      libx11-6 && \
    rm -rf /var/lib/apt/lists/*

# Set a consistent app workdir inside the image
WORKDIR /app

# Copy only the tv_ott_native_app folder to keep the Docker context small
COPY ./tv_ott_native_app /app

# Ensure entrypoint has LF endings and executable bit
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Guarantee build directories exist and provide compatibility path.
# - Create /app/build (real directory)
# - Create /tv_ott_native_app (real directory)
# - If /tv_ott_native_app/build does not exist, create a symlink to /app/build
RUN mkdir -p /app/build /tv_ott_native_app && \
    if [ -L /tv_ott_native_app/build ] && [ ! -e /tv_ott_native_app/build ]; then rm -f /tv_ott_native_app/build; fi && \
    if [ ! -e /tv_ott_native_app/build ]; then ln -s /app/build /tv_ott_native_app/build; fi

# Provide a compatibility environment variable for any scripts
ENV BUILD_DIR=/app/build

# Pre-create build directory to leverage Docker layer caching during cmake configure
RUN cmake -S /app -B /app/build

# Build the app at image build time (so the container can start instantly)
# Use a robust CPU core detection with a default fallback.
RUN CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" && \
    cmake --build /app/build -- -j"${CORES}"

# Default execution via entrypoint to keep consistency with dev/start environments
# Use exec-form so PID1 is our entrypoint script, which then execs the app.
ENTRYPOINT ["/app/entrypoint.sh"]
