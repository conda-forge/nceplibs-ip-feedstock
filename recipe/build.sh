#!/bin/bash

set -ex # Abort on error.

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${HOST} =~ .*darwin.* ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
else
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")
fi

mkdir build
cd build

# Make shared libs
cmake -G "${CMAKE_GENERATOR}" \
      "${CMAKE_ARGS}" \
      "${CMAKE_PLATFORM_FLAGS[@]}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH="${PREFIX}" \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_FIND_FRAMEWORK=NEVER \
      -DCMAKE_FIND_APPBUNDLE=NEVER \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_STATIC_LIBS=ON \
      -DOPENMP=ON \
      -DBLA_VENDOR=OpenBLAS \
      -DFTP_TEST_FILES=ON \
      -DBUILD_D=OFF \
      "${SRC_DIR}"
make
make install

# Tests to exclude for below when running in emulation
touch tests-to-exclude.txt
echo "test_polar_stereo_neighbor_budget_vector_grib1_4" >> tests-to-exclude.txt
echo "test_polar_stereo_neighbor_budget_vector_grib2_4" >> tests-to-exclude.txt
echo "test_rotatedB_direct_ncep_post_spectral_vector_grib2_4" >> tests-to-exclude.txt
echo "test_rotatedB_direct_spectral_vector_grib2_4" >> tests-to-exclude.txt
echo "test_rotatedB_spectral_scalar_grib1_4" >> tests-to-exclude.txt
echo "test_rotatedB_spectral_scalar_grib2_4" >> tests-to-exclude.txt
echo "test_rotatedB_spectral_vector_grib1_4" >> tests-to-exclude.txt
echo "test_rotatedB_spectral_vector_grib2_4" >> tests-to-exclude.txt

# Skip ctest when cross-compiling
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  ctest -VV --output-on-failure -j"${CPU_COUNT}" --exclude-from-file "tests-to-exclude.txt"
fi
