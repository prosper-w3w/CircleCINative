#!/bin/bash
set -e
set -x

export PLATFORM="21"
export CMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake

rm -rf .dist/
mkdir .dist/

# set the target - this will eventually be a for loop
cd ./.circleci
TARGETS=(armeabi-v7a arm64-v8a)
for TARGET in "${TARGETS[@]}"; do
  # remove any old builds
  if [ -d "build" ]; then
    rm -r build
  fi

  # make a build folder and cd into it
  mkdir build
  cd build

  # cmake build
  cmake ../../app/src/main/cpp \
    -DBUILD_TESTS=NO \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
    -DANDROID_NDK=${ANDROID_NDK_HOME} \
    -DANDROID_ABI="${TARGET}" \
    -DANDROID_PLATFORM=${PLATFORM} \
    -DANDROID_TOOLCHAIN=clang \
    -DANDROID_STL=c++_static \
    -DANDROID_CPP_FEATURES='exceptions;rtti' \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=../"${TARGET}"

  # make the lib
  make -j6

  # move the lib up a folder level - ultimately this might push to S3?
  if [ -d ../dist/"${TARGET}"/ ]; then
    rm -r ../dist/"${TARGET}"/
  fi
  mkdir ../dist/"${TARGET}"/
  mv lib*.so ../dist/"${TARGET}"/
  cd ..
done

tar -czf ../../circlenative-build-artifacts.tar.gz ../../.dist/
