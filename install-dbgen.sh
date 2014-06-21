#!/bin/sh
set -e
cd $(dirname $0)

TPCH_PROG=tpch_2_17_0
DBGEN_DIR=$SRC_DIR/$TPCH_PROG/dbgen

_echo() {
    echo "[$0] $1"
}

usage() {
    _echo "Usage: BIN_DIR=\$HOME/bin SRC_DIR=\$HOME/src $0"
}

ensure_directories() {
    if [ -z $BIN_DIR ]; then
        _echo 'Error: Please asssin bin directory to $BIN_DIR'
        usage
        exit 1
    fi
    if [ -z $SRC_DIR ]; then
        _echo 'Error: Please assign download and extract directory to $SRC_DIR'
        usage
        exit 1
    fi

    for dir in $BIN_DIR $SRC_DIR; do
        if [ ! -d $dir ]; then
            mkdir -pv $dir
        fi
    done
}

download_and_extract_dbgen() {
    if [ ! -f $SRC_DIR/$TPCH_PROG.zip ]; then
        _echo "Download $TPCH_PROG.zip ..."
        wget http://www.tpc.org/tpch/spec/$TPCH_PROG.zip -P $SRC_DIR
    fi
    if [ ! -d $SRC_DIR/$TPCH_PROG ]; then
        _echo "Extract $TPCH_PROG.zip ..."
        unzip $SRC_DIR/$TPCH_PROG -d $SRC_DIR
        rm -rf $SRC_DIR/__MACOSX
    fi
}

apply_patches_to_dbgen() {
    _echo "Apply patches ..."
    for file_to_patch in dss.ddl dss.ri makefile.suite tpcd.h; do
        patch -u -N $DBGEN_DIR/$file_to_patch < $file_to_patch.patch || true
    done
}

make_and_insall() {
    _echo "Make ..."
    make -f makefile.suite -C $DBGEN_DIR

    _echo "Install ..."
    for bin in dbgen qgen; do
        if [ ! -f $BIN_DIR/$bin ]; then
            cat > $BIN_DIR/$bin <<EOF
#!/bin/sh
cd $PWD/queries
exec "$DBGEN_DIR/$bin" "-b" "$DBGEN_DIR/dists.dss" "\$@"
EOF
            chmod +x $BIN_DIR/$bin
            _echo "Wrote $BIN_DIR/$bin"
        fi
    done
}

ensure_directories
download_and_extract_dbgen
apply_patches_to_dbgen
make_and_insall
