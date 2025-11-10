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

## Notes

- The entrypoint normalizes line endings and avoids heredoc-related issues that can cause `bash: -c: line X: syntax error: unexpected end of file`.
- CMakeLists.txt is configured with `RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}`, so the built binary is placed into the build directory and executed from there.
