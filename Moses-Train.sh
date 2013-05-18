#!/bin/bash

set -e
export SCRIPTS_ROOTDIR=`pwd`/tools/moses/scripts

function absname () {
    if [ "${1:0:1}" = "/" ]; then echo "$1"; else echo "$PWD/$1"; fi
}

if [ $# -ne 6 ]; then
    echo "Usage: $0 <corpus_prefix> <lm> <src> <dst> <wdir>" >&2; exit 1;
fi

CORPUS_PREFIX=`absname $1`
LM=`absname $2`
LM_N="$3"
SRC="$4"
DST="$5"
WDIR="$6"
mkdir -p $WDIR
${SCRIPTS_ROOTDIR}/training/train-model.perl -root-dir $WDIR \
    -external-bin-dir `pwd`/tools/bin \
    -corpus $CORPUS_PREFIX -f $SRC -e $DST -alignment grow-diag-final-and \
    -reordering msd-bidirectional-fe -lm 0:${LM_N}:$LM &> $WDIR.log
exit 0
