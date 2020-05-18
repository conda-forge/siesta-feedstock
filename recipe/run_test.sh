#!/bin/bash
set -e

echo "Running tests"
ls -l

for cmd in siesta transiesta tbtrans \
		  eigfat2plot gnubands mprop fat \
		  denchar Eig2DOS \
		  grid2cube grid_rotate grid_supercell \
		  fcbuild vibra \
		  mixps fractional \
		  readwf readwfx info_wfsx wfs2wfsx wfsx2wfs
do
    command -v $cmd
done

export OMPI_MCA_plm=isolated
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_rmaps_base_oversubscribe=yes

# Run H2O system
mkdir h2o

pushd h2o
cp ../Tests/Pseudos/H.psf .
cp ../Tests/Pseudos/O.psf .
cp ../Tests/h2o/h2o.fdf .
# if [[ "$mpi" == "nompi" ]]; then
#     siesta < h2o.fdf > h2o.out
# else
mpirun -np 1 siesta < h2o.fdf > h2o.out
# fi
popd
