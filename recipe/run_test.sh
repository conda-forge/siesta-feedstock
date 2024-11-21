#!/bin/bash
set -e

# This is just to ensure it works *better* on lone machines.
# Users on clusters should do something differently,
# or unset these.
export OMPI_MCA_plm=isolated
export OMPI_MCA_btl_vader_single_copy_mechanism=none
export OMPI_MCA_rmaps_base_oversubscribe=yes

echo "Checking that commands exists"
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

# Show the version of Siesta:
echo "Show siesta --version output:"
siesta --version
