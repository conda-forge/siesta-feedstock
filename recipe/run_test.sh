#!/bin/bash
set -e

echo "Running tests"
ls -l

for cmd in siesta tbtrans phtrans \
		  eigfat2plot gnubands mprop fat \
		  denchar Eig2DOS \
		  grid2cube grid_rotate grid_supercell \
		  fcbuild vibra \
		  mixps fractional \
		  readwf readwfx wfs2wfsx wfsx2wfs
do
    echo "checking cmd = $cmd"
    command -v $cmd
done

# This is just to ensure it works *better* on lone machines.
# Users on clusters should do something differently,
# or unset these.
export OMPI_MCA_plm=isolated
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_rmaps_base_oversubscribe=yes

# Run CG system
echo "Running CG test"
mkdir cg

pushd cg

cp -av ../Tests/08.GeometryOptimization/basejob.fdf cg.fdf
echo "SystemLabel cg" >> cg.fdf
echo "MD.TypeOfRun cg" >> cg.fdf
cp -av ../Tests/Pseudos/Mg.psf .
cp -av ../Tests/Pseudos/C.psf .
cp -av ../Tests/Pseudos/O.psf .
if [[ "$mpi" == "nompi" ]]; then
    siesta cg.fdf > cg.out
else
    mpirun siesta cg.fdf > cg.out
fi
echo "TEST START : cg"
cat cg.out
echo "TEST END : cg"

popd
