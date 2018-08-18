#!/bin/sh

# Run H2O system
mkdir h2o
cd h2o
cp $SRC_DIR/Tests/Pseudos/H.psf .
cp $SRC_DIR/Tests/Pseudos/O.psf .
cp $SRC_DIR/Tests/h2o/h2o.fdf .
siesta < h2o.fdf > h2o.out
cd ..
