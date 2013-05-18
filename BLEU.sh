#!/bin/bash

set -e
export LC_NUMERIC=C
BLEU=tools/moses/scripts/generic/multi-bleu.perl
HYP="$1"
REF="$2"
$BLEU $REF < $HYP | sed 's/,/ /g' | awk '{print $3}'
exit 0
