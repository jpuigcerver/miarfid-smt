#!/bin/bash

# Use L sentences for MERT tuning
L=200
for DATA in $@; do
    shuf $DATA > /tmp/$$.tmp
    head -n $L /tmp/$$.tmp > ${DATA}.mert
    tail -n +$[L+1] /tmp/$$.tmp > ${DATA}.train
done
exit 0
