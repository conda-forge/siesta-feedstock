#!/bin/bash

# error on faulty execution
set -ex

# Remove __FILE__ lines in utils file.
sed -i -e "s:__FILE__:'fdf/utils.F90':g" Src/fdf/utils.F90

echo "Runing with mpi=$mpi and blas=$blas_impl"
echo "Build on target_platform=$target_platform"
echo "Build on uname=$(uname)"

# Use the default utilities, for now.
cd Obj
../Src/obj_setup.sh

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
    repl="$repl;s:%AR%:$GCC_AR:g"
else
    repl="$repl;s:%AR%:$AR:g"
fi
if [[ -n "$GCC_RANLIB" ]]; then
    repl="$repl;s:%RANLIB%:$GCC_RANLIB:g"
else
    repl="$repl;s:%RANLIB%:$RANLIB:g"
fi
repl="$repl;s:%CC%:$CC:g"
repl="$repl;s:%FC%:$FC:g"
# No OpenMP!
repl="$repl;s:%CFLAGS%:${CFLAGS//-fopenmp/}:g"
repl="$repl;s:%FFLAGS%:${FFLAGS//-fopenmp/}:g"
repl="$repl;s:%FFLAGS_DEBUG%:${DEBUG_FFLAGS//-fopenmp/}:g"
repl="$repl;s:%INCFLAGS%:-I$PREFIX/include:g"
repl="$repl;s:%LDFLAGS%:-L$PREFIX/lib $LDFLAGS:g"

if [[ "$mpi" == "nompi" ]]; then
  sed -e "$repl" $RECIPE_DIR/arch.make.SEQ > arch.make
else
  sed -e "$repl" $RECIPE_DIR/arch.make.MPI > arch.make
fi
echo "<<< arch.make >>>"
cat arch.make
echo "<<< arch.make done >>>"

function mkcp {
    local target=$1
    shift
    local exe=$target
    if [ $# -ge 1 ]; then
	    exe=$1
	    shift
    fi
    echo "RUNNING: make $target"
    make $target
    cp -av $target $PREFIX/bin/$exe
    make clean
}

# First make a few of the libraries to check that they work!
make libxmlparser.a
# Try and build FoX to catch any debugs
# make FoX/.config || cat FoX/config.log

ls -l
make version
cat compinfo.F90
mkcp siesta
make version
mkcp transiesta

cd ../Util/Bands
mkcp eigfat2plot
mkcp gnubands

cd ../COOP
mkcp mprop
mkcp fat

cd ../Denchar/Src
mkcp denchar

cd ../../Eig2DOS
mkcp Eig2DOS

# Apparently the NetCDF module can *only* be found in Siesta compilation
#    ???
#cd ../Gen-basis
# mkcp gen-basis
# mkcp ioncat

cd ../Grid
mkcp grid2cube
# mkcp cdf2xsf
# mkcp cdf2grid
mkcp grid_rotate
mkcp grid_supercell

cd ../Optical
mkcp optical
mkcp optical_input

cd ../TBTrans
mkcp tbtrans tbtrans_old
cd ../TBTrans_rep
mkcp tbtrans

cd ../Vibra/Src
mkcp fcbuild
mkcp vibra

cd ../../VCA
mkcp mixps
mkcp fractional

cd ../WFS
mkcp readwf
mkcp readwfx
mkcp info_wfsx
mkcp wfs2wfsx
mkcp wfsx2wfs
# mkcp wfsnc2fsx
