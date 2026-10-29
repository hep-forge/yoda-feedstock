#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

autoconf

# Make sure the cython sources are recompiled (-f: 2.1.4 no longer ships them)
rm -f pyext/yoda/core.cpp pyext/yoda/util.cpp

declare -a CONFIGURE_ARGS
CONFIGURE_ARGS+=("--prefix=${PREFIX}")
CONFIGURE_ARGS+=("--libdir=${PREFIX}/lib")
CONFIGURE_ARGS+=("--with-zlib=${PREFIX}")

if [ "$build_platform" != "$target_platform" ]; then
    CONFIGURE_ARGS+=("ac_cv_file_pyext_yoda_core_cpp=no")
fi
export CXXFLAGS="-fPIC -std=c++17"
./configure "${CONFIGURE_ARGS[@]}"

# HDF5 >= 2 reports its extra link libraries as a CMake list
# ("-lm;-ldl;-laws-c-s3;..."). In the generated Makefiles the shell splits
# that at each ';' ("-ldl: command not found"), and yoda-config would hand it
# to users. Turn the separators into spaces where configure stored the values
# and regenerate every file from them. Every ';' inside these entries is a
# separator (config.status may wrap the value right after one).
awk '/^S\["HDF5_[A-Z]*LIBS"\]=/{f=1} f{gsub(/;/," ")} f && !/\\$/{f=0} {print}' \
    config.status > config.status.fixed
cat config.status.fixed > config.status && rm config.status.fixed
./config.status > /dev/null

make -j${CPU_COUNT}
make -j${CPU_COUNT} install
