#!/bin/bash
set -eu
cd $(dirname $0)

usage() {
    echo "Usage: [PREFIX=\$HOME] $0 <postgres|mysql>"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

case $1 in
    postgres|mysql)
    ;;
    *)
        usage
        exit 1
        ;;
esac

BASE_DIR=$PWD
DATABASE=$1
TPCH_PROG=tpch_2_17_0
: ${PREFIX:=$HOME}
PREFIX=$(readlink -f $PREFIX)
BIN_DIR=$PREFIX/bin
SRC_DIR=$PREFIX/src
SHARE_DIR=$PREFIX/share/dbgen
DBGEN_DIR=$SRC_DIR/$TPCH_PROG/dbgen

ensure_directories() {
    for dir in $BIN_DIR $SRC_DIR $SHARE_DIR; do
        if [ ! -d $dir ]; then
            mkdir -pv $dir
        fi
    done
}

download_and_extract_dbgen() {
    pushd $SRC_DIR
    if [ ! -f $TPCH_PROG.zip ]; then
        echo "Download $TPCH_PROG.zip ..."
        curl -LO http://www.tpc.org/tpch/spec/$TPCH_PROG.zip
    fi
    if [ ! -d $TPCH_PROG ]; then
        echo "Extract $TPCH_PROG.zip ..."
        unzip $TPCH_PROG
        rm -rf __MACOSX
    fi
    popd
}

apply_patches_to_dbgen() {
    pushd $DATABASE
    echo "Apply patches ..."
    for file_to_patch in config.h dss.ddl dss.ri makefile.suite tpcd.h; do
        # restore from backup
        if [ -f $DBGEN_DIR/$file_to_patch.orig ]; then
            cp -fp $DBGEN_DIR/$file_to_patch.orig $DBGEN_DIR/$file_to_patch
        fi
        if [ -f $file_to_patch.patch ]; then
            patch -bu $DBGEN_DIR/$file_to_patch < $file_to_patch.patch
        fi
    done
    popd
}

make_and_insall() {
    pushd $DBGEN_DIR
    echo "Make ..."
    make -f makefile.suite clean
    make -f makefile.suite

    echo "Install ..."
    for f in answers check_answers/cmpq.pl check_answers/colprecision.txt dbgen qgen dists.dss dss.ddl dss.ri; do
        cp -fpr $f $SHARE_DIR
        echo "Copied to $SHARE_DIR/$f"
    done

    if [ -d $BASE_DIR/$DATABASE/queries ]; then
        cp -fpr $BASE_DIR/$DATABASE/queries $SHARE_DIR
        echo "Copyed to $SHARE_DIR/queries"
    fi

    for bin in dbgen qgen; do
        cat > $BIN_DIR/$bin <<EOF
#!/bin/sh
EOF
        if [ "$bin" = 'qgen' ]; then
            cat >> $BIN_DIR/$bin <<EOF
cd $SHARE_DIR/queries
EOF
        fi
        cat >> $BIN_DIR/$bin <<EOF
exec "$SHARE_DIR/$bin" "-b" "$SHARE_DIR/dists.dss" "\$@"
EOF
        chmod +x $BIN_DIR/$bin
        echo "Wrote $BIN_DIR/$bin"
    done
    popd
}

ensure_directories
download_and_extract_dbgen
apply_patches_to_dbgen
make_and_insall
