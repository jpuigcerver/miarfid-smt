#!/bin/bash

set -e
export LC_NUMERIC=C

SRILM=tools/srilm/bin/i686-m64/ngram-count
DATA=( )
ORDER=( 3 )

function usage () {
    cat <<-EOF >&2
Usage: $PROG -d <data> [OPTIONS]
Creates a LM from training data.

Options:
    -h               show this help
    -d <data> ...    training files
    -o <n> ...       N-gram order.
                     default: $ORDER
EOF
}

while [ "${1:0:1}" = "-" ]; do
    case "$1" in
	"-h")
	    usage
	    exit 0
	    ;;
	"-d")
	    shift 1
	    DATA=( )
	    while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
		DATA=( ${DATA[@]} $1 ); shift 1;
	    done
	    ;;
	"-o")
	    shift 1
	    ORDER=( )
	    while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
		ORDER=( ${ORDER[@]} $1 ); shift 1;
	    done
	    ;;
	*)
	    echo "Unknown option: \"$1\"" >&2; exit 1
    esac
done

for data in ${DATA[@]}; do
    for o in ${ORDER[@]}; do
	echo "Creating \"$data.lm$o\"...">&2;
	$SRILM -order $o -unk -interpolate -text $data \
	    -lm $data.lm$o
    done
done
