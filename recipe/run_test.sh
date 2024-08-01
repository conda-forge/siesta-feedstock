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

# Show the version of Siesta:
echo "Show siesta --version output:"
siesta --version || echo "Forced succes!"
