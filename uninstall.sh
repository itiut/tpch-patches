#!/bin/bash
set -eu
cd $(dirname $0)

: ${PREFIX:=$HOME}
PREFIX=$(readlink -f $PREFIX)
BIN_DIR=$PREFIX/bin
SHARE_DIR=$PREFIX/share/dbgen

for f in $BIN_DIR/dbgen $BIN_DIR/qgen $SHARE_DIR; do
    if [ -e $f ]; then
        rm -rf $f
        echo "Removed $f"
    fi
done
