#!/bin/sh

ls -l

# Run H2O system
mkdir h2o
cd h2o
cp ../Tests/Pseudos/H.psf .
cp ../Tests/Pseudos/O.psf .
cp ../Tests/h2o/h2o.fdf .
siesta < h2o.fdf > h2o.out
cd ..
