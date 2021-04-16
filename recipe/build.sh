#!/bin/bash

# Remove __FILE__ lines in utils file.
sed -i -e "s:__FILE__:'fdf/utils.F90':g" Src/fdf/utils.F90

echo "Runing with mpi=$mpi and blas=$blas_impl"

# Use the default utilities, for now.
cd Obj
../Src/obj_setup.sh

if [[ -n "$GCC" ]]; then
    repl="s:%CC%:$GCC:g"
else
    repl="s:%CC%:$CC:g"
fi
repl="$repl;s:%CFLAGS%:$CFLAGS:g"
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
repl="$repl;s:%FFLAGS%:$FFLAGS:g"
repl="$repl;s:%FFLAGS_DEBUG%:$DEBUG_FFLAGS:g"
repl="$repl;s:%INCFLAGS%:-I$PREFIX/include:g"
repl="$repl;s:%LDFLAGS%:-L$PREFIX/lib:g"

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
    [ -e compinfo.F90 ] && cat compinfo.F90
    cp $target $PREFIX/bin/$exe
    make clean
}

# First make a few of the libraries to check that they work!
make libxmlparser.a
# Try and build FoX to catch any debugs
# make FoX/.config || cat FoX/config.log

set -x
ls -l
make version
cat compinfo.F90
mkcp siesta
make version

cd ../Util/Bands
mkcp eigfat2plot
mkcp gnubands

cd ../COOP
mkcp mprop
mkcp fat
mkcp spin_texture

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

cd ../Grimme
mkcp fdf2grimme

cd ../Macroave/Src
mkcp macroave

cd ../../TS/TBtrans
mkcp tbtrans
cd ../ts2ts
mkcp ts2ts
cd ../tshs2tshs
mkcp tshs2tshs
cd ../
cp tselecs.sh $PREFIX/bin/tselecs.sh

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
