#!/bin/bash

# Divide the input data in K training/validation partitions
K=5
for ORIG_DATA in $@; do
    NDATA=$(cat ${ORIG_DATA} | wc -l)
    NXF=$(echo "($NDATA + $K - 1) / $K" | bc)
    echo "Split \"${ORIG_DATA}\" ($NDATA li.) into $K parts (approx. $NXF li.)"
    shuf ${ORIG_DATA} | split -d -l $NXF - ${ORIG_DATA}.valid
    for f in ${ORIG_DATA}.valid*; do
	for f2 in ${ORIG_DATA}.valid*; do
	    [ $f == $f2 ] && { continue; }
	    cat $f2
	done > ${f/.valid/.train}
    done
done
exit 0
