#!/bin/sh

# Remove __FILE__ lines in utils file.
sed -i -e "s:__FILE__:'fdf/utils.F90':g" Src/fdf/utils.F90

# Use the default utilities, for now.
cd Obj
../Src/obj_setup.sh

cp $RECIPE_DIR/arch.make.MPI arch.make

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

cd ../Gen-basis
mkcp gen-basis
mkcp ioncat

cd ../Grid
mkcp grid2cube
mkcp cdf2xsf
mkcp cdf2grid
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
mkcp wfsnc2fsx
