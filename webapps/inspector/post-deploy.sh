#!/bin/bash

# target based on root dir
R5PRO_ROOT=$1
PLUGIN=$(realpath ./inspector.jar)

echo "Moving ${PLUGIN} to ${R5PRO_ROOT}..."
mv -v "$PLUGIN" "${R5PRO_ROOT}/plugins/"

echo "Complete."
