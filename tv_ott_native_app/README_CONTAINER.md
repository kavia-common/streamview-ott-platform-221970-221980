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

## Build Directory Convention

- Inside the container image, the application root is `/app`.
- The entrypoint defaults to use `/app/build` as the build directory when running inside the container.
- You can override this by setting the `BUILD_DIR` environment variable when running the container:
  docker run --rm -e BUILD_DIR=/app/custom_build -it tv_ott_native_app:local
- For local, non-container runs (executing `entrypoint.sh` directly), the default build directory is `<repo>/streamview-ott-platform-221970-221980/tv_ott_native_app/build`.

This ensures external orchestrators that expect a stable build path (like `/app/build`) will find a valid directory, preventing errors such as "`.../build is not a directory`".

## Notes

- The entrypoint normalizes line endings and avoids heredoc-related issues that can cause `bash: -c: line X: syntax error: unexpected end of file`.
- CMakeLists.txt is configured with `RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}`, so the built binary is placed into the build directory and executed from there.
