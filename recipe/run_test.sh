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

# Run H2O system
echo "Running h2o test"
mkdir h2o

pushd h2o
cp ../Tests/Pseudos/H.psf .
cp ../Tests/Pseudos/O.psf .
cp ../Tests/h2o/h2o.fdf .
if [[ "$mpi" == "nompi" ]]; then
    siesta < h2o.fdf > h2o.out
else
    mpirun siesta < h2o.fdf > h2o.out
fi
echo "TEST START : h2o"
cat h2o.out
echo "TEST END : h2o"

popd
