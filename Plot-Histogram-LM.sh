#!/bin/bash
set -e

FORMAT=x11

function usage () {
    cat <<EOF
Usage: $0 [OPTIONS] <file>

Options:
   -h        show this help
   -f <fmt>  plot format: png, ps, x11
             default: $FORMAT
EOF
}

while [ "${1:0:1}" = "-" ]; do
    case "$1" in
        -h)
            usage; exit 0
            ;;
        -f)
            FORMAT=$2; shift 2;
            ;;
        *)
            echo "Unknown option: $1" >&2; exit 1
    esac
done

DATA="$1"
[ "$DATA" = "" ] && {
    echo "You must indicate a data file" >&2; exit 1
}

case "$FORMAT" in
    png)
        OUTPUT="set output '$DATA.png'"
        TERM="set term png"
        PERSIST=
        ;;
    ps)
        OUTPUT="set output '$DATA.ps'"
        TERM="set term postscript enhanced color"
        PERSIST=
        ;;
    x11)
        OUTPUT=
        TERM="set term x11"
        PERSIST="-persist"
        ;;
    *)
        echo "Unknown format: $FORMAT" >&2; exit 1
esac

{
    cat <<EOF
$TERM
$OUTPUT
set style data histogram
set style histogram errorbars linewidth 0
set style fill solid 1.0 border 0
set key left top
set bars front
set xlabel 'N-GRAM SIZE'
set ylabel 'BLEU'
plot '$DATA' u 2:(\$2-\$3):(\$2+\$3):xticlabels(1) t 'ES > EN', \
'$DATA' u 4:(\$4-\$5):(\$4+\$5):xticlabels(1) t 'EN > ES'
EOF
} | gnuplot $PERSIST


exit 0
