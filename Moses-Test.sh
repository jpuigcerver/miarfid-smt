#!/bin/bash

set -e
export LC_NUMERIC=C
MOSES=tools/moses/bin/moses

if [ $# -lt 3 ]; then
    echo "Usage: $0 <model-ini> <src> <dst-hyp> [<dst-ref>]" >&2
    exit 1
fi
MODEL="$1"; SRC="$2"; DST_HYP="$3"; DST_REF="$4";
mkdir -p `dirname $DST_HYP`
$MOSES -f $MODEL < $SRC > $DST_HYP 2> $DST_HYP.log
if [ "$DST_REF" != "" ]; then
    ./BLEU.sh $DST_HYP $DST_REF
fi

