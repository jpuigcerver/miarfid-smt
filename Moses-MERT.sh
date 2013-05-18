#!/bin/bash

set -e
export SCRIPTS_ROOTDIR=`pwd`/tools/moses/scripts
export BIN_ROOTDIR=`pwd`/tools/moses/bin

function absname () {
    if [ "${1:0:1}" = "/" ]; then echo "$1"; else echo "$PWD/$1"; fi
}

MDL=`absname $1`
SRC=`absname $2`
DST=`absname $3`
WDIR=`absname $4`
mkdir -p $WDIR
$SCRIPTS_ROOTDIR/training/mert-moses.pl $SRC $DST \
    $BIN_ROOTDIR/moses $MDL/model/moses.ini --mertdir=$BIN_ROOTDIR \
    --working-dir=$WDIR --threads=6 &> $WDIR.log
exit 0
