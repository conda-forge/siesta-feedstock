#!/bin/bash

# error on faulty execution
set -ex

echo "Runing with mpi=$mpi and blas=$blas_impl"
echo "Build on target_platform=$target_platform"
echo "Build on uname=$(uname)"

# OpenMPI has the *.mod files in /lib
export FFLAGS="$FFLAGS -I$PREFIX/lib"

#if [[ "$target_platform" == linux-* || "$target_platform" == "osx-arm64"  ]]; then
  # Workaround for https://github.com/conda-forge/scalapack-feedstock/pull/30#issuecomment-1061196317
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

  # Currently there is a problem with the compiler on Mac
  # The version-info will be created in a wrong setup...
  # So we have to do something else...
  # This will just mean we won't parse the flags etc.
  # Should not be a problem.
  sed -i -e 's:@:#:g' Src/version-info-template.inc
else
  export SONAME="-Wl,-soname,"
fi

if [[ "$mpi" != "nompi" ]]; then
  echo "passing on setting CC and FC for non-mpi"
  export CC=mpicc
  export FC=mpifort
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

if [[ "$mpi" == "nompi" ]]; then
  MPI=OFF
else
  MPI=ON
fi

# For flook compilation, we set LUA_DIR so that lua is not compiled again
# This makes flook use conda's lua version
export LUA_DIR=${PREFIX}

cmake_opts=(
  # Add NetCDF
  "-DWITH_LIBXC=on"
  "-DWITH_NCDF=on"

  # Enable flook
  "-DWITH_FLOOK=on"

  # MPI
  "-DWITH_MPI=${MPI}"

  # We will fetch the compatible versions
  "-DLIBFDF_FIND_METHOD=fetch"
  "-DLIBGRIDXC_FIND_METHOD=fetch"
  "-DLIBPSML_FIND_METHOD=fetch"
  "-DXMLF90_FIND_METHOD=fetch"

  "-DCMAKE_BUILD_TYPE=Release"
  "-DCMAKE_INSTALL_LIBDIR=lib"

  # Request that the makefile is verbose
  "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"

  # I don't think these are required.
  # They are intended to omit linking to direct
  "-DCMAKE_FIND_FRAMEWORK=NEVER"
  "-DCMAKE_FIND_APPBUNDLE=NEVER"

  # To not clutter things
  "-DCMAKE_INSTALL_PREFIX=$PREFIX"
)

cmake -S. -Bobj_cmake "${cmake_opts[@]}"

echo ">>>>>>>"
echo "Showing version-info.inc: "
cat obj_cmake/Src/version-info.inc
echo ">>>>>>>"
cmake --build obj_cmake --target install
