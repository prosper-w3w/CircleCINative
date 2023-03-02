#!/bin/bash
set -e
set -x

export ANDROID_NDK_HOME="/Users/prosperekweike/Library/Android/sdk"
export CMAKE_HOME=${ANDROID_NDK_HOME}/cmake/3.22.1/
export CMAKE=${CMAKE_HOME}/bin/cmake
export PLATFORM="21"
export CMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/ndk/25.2.9519653/build/cmake/android.toolchain.cmake
ACTUAL_NDK_HOME=${ANDROID_NDK_HOME}/ndk/25.2.9519653

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
  ${CMAKE}  ../../app/src/main/cpp \
    -DBUILD_TESTS=NO \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
    -DANDROID_NDK=${ACTUAL_NDK_HOME} \
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
  if [ -d ../"${TARGET}"/ ]; then
    rm -r ../"${TARGET}"/
  fi
  mkdir ../"${TARGET}"/
  mv lib*.so ../"${TARGET}"/
  cd ..
done
