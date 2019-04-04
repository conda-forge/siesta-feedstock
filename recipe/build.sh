#!/bin/bash

# Remove __FILE__ lines in utils file.
sed -i -e "s:__FILE__:'fdf/utils.F90':g" Src/fdf/utils.F90

echo "Runing with mpi=$mpi and blas=$blas_impl"

# Use the default utilities, for now.
cd Obj
../Src/obj_setup.sh

if [[ "$mpi" == "nompi" ]]; then
    cp $RECIPE_DIR/arch.make.SEQ arch.make
else
    cp $RECIPE_DIR/arch.make.MPI arch.make
fi

function mkcp {
    local target=$1
    shift
    local exe=$target
    if [ $# -ge 1 ]; then
	exe=$1
	shift
    fi
    make $target
    cp $target $PREFIX/bin/$exe
    make clean
}

# First make a few of the libraries to check that they work!
make libxmlparser.a

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
