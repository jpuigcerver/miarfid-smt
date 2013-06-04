#!/bin/bash

K=5
PREP_VAL=1
while [ "${1:0:1}" = "-" ]; do
    case "$1" in
        -h)
            cat <<EOF
Usage: $0 [OPTIONS] FILES...
Options:
   -h          show this help
   -k <folds>  number of partitions of the data
               default: $K
   -cv <0|1>   prepare data for cross-validation
               default: ${PREP_VAL}
EOF
            exit 0;
            ;;
        -k)
            K=$2; shift 2;
            ;;
        -cv)
            PREP_VAL=$2; shift 2;
            ;;
        *)
            echo "Unknown opion: $1" >&2; exit 1;
    esac
done

# Divide the input data in K training/validation partitions
for ORIG_DATA in $@; do
    NDATA=$(cat ${ORIG_DATA} | wc -l)
    NXF=$(echo "($NDATA + $K - 1) / $K" | bc)
    echo "Split \"${ORIG_DATA}\" ($NDATA li.) into $K parts (approx. $NXF li.)"
    if [ $PREP_VAL -eq 1 ]; then
        shuf ${ORIG_DATA} | split -d -l $NXF - ${ORIG_DATA}.valid
        for f in ${ORIG_DATA}.valid*; do
	    for f2 in ${ORIG_DATA}.valid*; do
	        [ $f == $f2 ] && { continue; }
	        cat $f2
	    done > ${f/.valid/.train}
        done
    else
        shuf ${ORIG_DATA} | split -d -l $NXF - ${ORIG_DATA}.part
    fi
done
exit 0
