#!/bin/bash

# error on faulty execution
set -ex

echo "Runing with mpi=$mpi and blas=$blas_impl"
echo "Build on target_platform=$target_platform"
echo "Build on uname=$(uname)"

#if [[ "$target_platform" == linux-* || "$target_platform" == "osx-arm64"  ]]; then
  # Workaround for https://github.com/conda-forge/scalapack-feedstock/pull/30#issuecomment-1061196317
  export FFLAGS="$FFLAGS -fallow-argument-mismatch"
  export DEBUG_FFLAGS="$DEBUG_FFLAGS -fallow-argument-mismatch"
  export OMPI_FCFLAGS="$FFLAGS"
#fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  # This is only used by open-mpi's mpicc
  # ignored in other cases
  export OMPI_CC=$CC
  export OMPI_CXX=$CXX
  export OMPI_FC=$FC
  export OPAL_PREFIX=$PREFIX
fi

if [[ "$(uname)" == "Darwin" ]]; then
  # Fix headerpad-max-install-error
  # install_name_tool: changing install names or rpaths can't be redone for
  #  (for architecture x86_64) because larger updated load commands do not fit (the program must be relinked, and you may need to use -headerpad or -headerpad_max_install_names)
  export SONAME="-Wl,-install_name,@rpath/"
  export LDFLAGS="${LDFLAGS} -headerpad_max_install_names"
else
  export SONAME="-Wl,-soname,"
fi

if [[ "$mpi" != "nompi" ]]; then
  # This is not necessary as the arch.make files
  # handles this correctly
  echo "passing on setting CC and FC for non-mpi"
  #export CC=mpicc
  #export FC=mpifort
fi

# Get the version
echo "CC version string: $($CC --version | head -1)"

if [[ -n "$GCC_AR" ]]; then
  export AR=$GCC_AR
fi
if [[ -n "$GCC_RANLIB" ]]; then
  export RANLIB=$GCC_RANLIB
fi
export LDFLAGS="-L$PREFIX/lib $LDFLAGS"

opts=
opts="$opts -DCMAKE_BUILD_TYPE=Release"
opts="$opts -DCMAKE_INSTALL_PREFIX=$PREFIX"
opts="$opts -DCMAKE_INSTALL_LIBDIR=lib"

opts="$opts -DCMAKE_FIND_FRAMEWORK=NEVER"
opts="$opts -DCMAKE_FIND_APPBUNDLE=NEVER"

if [[ "$mpi" == "nompi" ]]; then
  opts="$opts -DWITH_MPI=no"
else
  opts="$opts -DWITH_MPI=yes"
fi

# Add NetCDF
opts="$opts -DWITH_LIBXC=on"
opts="$opts -DWITH_NCDF=on"

# We will fetch the compatible versions
opts="$opts -DLIBFDF_FIND_METHOD=fetch"
opts="$opts -DLIBGRIDXC_FIND_METHOD=fetch"
opts="$opts -DLIBPSML_FIND_METHOD=fetch"
opts="$opts -DLIBXMLF90_FIND_METHOD=fetch"

cmake -S. -Bobj_cmake $opts
cmake --build obj_cmake --target install
