# tv_ott_native_app Container

This container builds and runs the native Qt6 application using CMake.

## Build

From the repository root:

- Build the image:
  docker build -f streamview-ott-platform-221970-221980/tv_ott_native_app/Dockerfile -t tv_ott_native_app:local ./streamview-ott-platform-221970-221980

## Run

- Run the container:
  docker run --rm -it tv_ott_native_app:local

The container uses a robust entrypoint.sh to configure and build (idempotently) and then execute the `MainApp` binary.

## Build Directory Convention and Path Guarantees

- Inside the container image, the application root is `/app`.
- The default build directory is `/app/build`.
- For compatibility with orchestrators that reference the legacy path `/tv_ott_native_app/build`, the image ensures:
  - `/app/build` exists as a real directory at image build time.
  - `/tv_ott_native_app` exists as a real directory.
  - `/tv_ott_native_app/build` exists as either a directory or a symlink to `/app/build`.
- The entrypoint maintains these guarantees at runtime (idempotent), recreating a missing directory or fixing a broken symlink if needed.

### Environment Variable

- You can override the build path by setting `BUILD_DIR`:
  docker run --rm -e BUILD_DIR=/app/custom_build -it tv_ott_native_app:local
- The entrypoint exports `BUILD_DIR` after resolution so any sub-scripts share the same value.

### Local (non-container) runs

- When executing `entrypoint.sh` directly on your machine, the default build directory is `<repo>/streamview-ott-platform-221970-221980/tv_ott_native_app/build`.

This ensures external orchestrators that expect a stable build path (like `/tv_ott_native_app/build` or `/app/build`) will find a valid directory, preventing errors such as "`.../build is not a directory`".

## Notes

- The entrypoint normalizes line endings and avoids heredoc-related issues that can cause `bash: -c: line X: syntax error: unexpected end of file`.
- CMakeLists.txt is configured with `RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}`, so the built binary is placed into the build directory and executed from there.
- The entrypoint is shipped with executable permissions and rechecked in the Dockerfile using `chmod +x /app/entrypoint.sh`.
