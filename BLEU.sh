#!/bin/bash
set -e
export LC_NUMERIC=C
BLEU=tools/moses/scripts/generic/multi-bleu.perl

if [ $# -ne 2 ]; then
    echo "Usage: $0 <hyp> <ref>" >&2;
    exit 1
fi
HYP="$1"
REF="$2"
$BLEU $REF < $HYP | sed 's/,/ /g' | awk '{print $3}'
exit 0
