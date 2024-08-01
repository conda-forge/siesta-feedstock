#!/bin/bash

# error on faulty execution
set -ex

echo "Runing with mpi=$mpi and blas=$blas_impl"
echo "Build on target_platform=$target_platform"
echo "Build on uname=$(uname)"

if [[ "$mpi" == "nompi" ]]; then
  MPI=OFF
else
  MPI=ON
fi

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

  # Turn off these things when cross compiling
  ELPA=off
  D3=off
  
  cmake_crosscomp_opts=(
    # Mock tests when cross-compiling
    "-Dblas_cdotu_return_convention_EXITCODE=0"
    "-DWITH_QP_EXITCODE=0"
    "-DWITH_XDP_EXITCODE=0"

    # Force specify the kinds for cross-compilation
    "-DSIESTA_REAL_KINDS='4;8'"
    "-DSIESTA_INTEGER_KINDS='4;8'"
  )

else
  ELPA=${MPI}
  D3=on
  cmake_crosscomp_opts=()
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
  # It says something like:
  #
  #   At line 68 of file /Users/runner/miniforge3/conda-bld/siesta_1715602566272/work/obj_cmake/Src/version-info.inc (unit = 6, file = 'stdout')
  #   Fortran runtime error: Missing initial left parenthesis in format
  #   all
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

# For flook compilation, we set LUA_DIR so that lua is not compiled again
# This makes flook use conda's lua version
export LUA_DIR=${PREFIX}

cmake_opts=(
  # Add NetCDF
  "-DSIESTA_WITH_NCDF=on"
  "-DSIESTA_WITH_LIBXC=on"

  # Enable flook
  "-DSIESTA_WITH_FLOOK=on"
  
  # Disable DFTD3 when cross compiling, because it uses test-drive, which
  # fails to compile
  "-DSIESTA_WITH_DFTD3=${D3}"

  # MPI
  "-DSIESTA_WITH_MPI=${MPI}"

  # ELPA
  "-DSIESTA_WITH_ELPA=${ELPA}"

  # We will fetch the compatible versions
  "-DSIESTA_FIND_METHOD=fetch"
  "-DLIBFDF_FIND_METHOD=fetch"
  "-DLIBGRIDXC_FIND_METHOD=fetch"
  "-DLIBPSML_FIND_METHOD=fetch"
  "-DXMLF90_FIND_METHOD=fetch"

  # Tests should not be runned with MPI (problems with ssh | rsh)
  "-DSIESTA_TESTS_MPI_NUMPROCS=1"
    
  # Avoid SIESTA setting its default fortran flags for release.
  # In particular, it sets -march=native, which does not work
  # when cross compiling (or at least for osx_arm64)
  "-DFortran_FLAGS_RELEASE=-O3"
  "-DC_FLAGS_RELEASE=-O3"
  "-DCXX_FLAGS_RELEASE=-O3"

  "-DCMAKE_BUILD_TYPE=Release"
  "-DCMAKE_INSTALL_LIBDIR=lib"

  # Request that the makefile is verbose
  "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"

  # I don't think these are required.
  # They are intended to omit linking to direct
  "-DCMAKE_FIND_FRAMEWORK=NEVER"
  "-DCMAKE_FIND_APPBUNDLE=NEVER"
)


cmake ${CMAKE_ARGS} -S. -Bobj_cmake "${cmake_opts[@]}" "${cmake_crosscomp_opts[@]}"

echo ">>>>>>>"
echo "Showing version-info.inc: "
cat -v obj_cmake/Src/version-info.inc
echo ">>>>>>>"
cmake --build obj_cmake -j 2 --target install


if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  # Cross-compilation cannot run tests
  exit 0
fi

# Run tests in the build-directory, this is important since the tests folders
# get deleted after build!

# This is just to ensure it works *better* on lone machines.
# Users on clusters should do something differently,
# or unset these.
export OMPI_MCA_plm=isolated
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_rmaps_base_oversubscribe=yes

echo "Running tests"
pushd obj_cmake/Tests/08.GeometryOptimization
SIESTA_TESTS_VERIFY=1 ctest -L simple || echo "Accepted fail!"
popd
