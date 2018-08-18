#!/bin/sh

# Test command:
cat <<EOF > RUN.fdf
Do nothing
EOF

siesta < RUN.fdf || echo SHOULD FAIL
rm RUN.fdf
