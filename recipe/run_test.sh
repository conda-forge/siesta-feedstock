#!/bin/sh

# Test command:
cat <<EOF > RUN.fdf
Do nothing
EOF

siesta < RUN.fdf
[ $? -eq 0 ] && echo Failed
rm RUN.fdf
