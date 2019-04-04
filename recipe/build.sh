#!/bin/bash

# Remove __FILE__ lines in utils file.
sed -i -e "s:__FILE__:'fdf/utils.F90':g" Src/fdf/utils.F90

echo "Runing with mpi=$mpi and blas=$blas_impl"

# Use the default utilities, for now.
cd Obj
../Src/obj_setup.sh

# In 4.0 we do not use OpenMP!
repl="s:%CC%:$GCC:g"
repl="$repl;s:%CFLAGS%:${CFLAGS//-fopenmp/}:g"
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
repl="$repl;s:%FC%:$FC:g"
repl="$repl;s:%FFLAGS%:${FFLAGS//-fopenmp/}:g"
repl="$repl;s:%FFLAGS_DEBUG%:${DEBUG_FFLAGS//-fopenmp/}:g"
repl="$repl;s:%LDFLAGS%:-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib:g"

if [[ "$mpi" == "nompi" ]]; then
    sed -e "$repl" $RECIPE_DIR/arch.make.SEQ > arch.make
else
    sed -e "$repl" $RECIPE_DIR/arch.make.MPI > arch.make
fi

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
    cp $target $PREFIX/bin/$exe
    make clean
}

# First make a few of the libraries to check that they work!
make libxmlparser.a
# Try and build FoX to catch any debugs
make FoX/.config || cat FoX/config.log

mkcp siesta
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
#mkcp gen-basis
#mkcp ioncat

cd ../Grid
mkcp grid2cube
#mkcp cdf2xsf
#mkcp cdf2grid
mkcp grid_rotate
mkcp grid_supercell

cd ../TBTrans_rep
mkcp tbtrans

cd ../TBTrans
mkcp tbtrans tbtrans_old

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
#mkcp wfsnc2fsx
