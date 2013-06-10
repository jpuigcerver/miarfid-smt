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
        PERSIST=
        TERM="set term png"
        ;;
    ps)
        OUTPUT="set output '$DATA.ps'"
        PERSIST=
        TERM="set term postscript enhanced color"
        ;;
    x11)
        OUTPUT=
        PERSIST="-persist"
        TERM="set term x11"
        ;;
    *)
        echo "Unknown format: $FORMAT" >&2; exit 1
esac

{
    cat <<EOF
$TERM
$OUTPUT
#set style data histogram
#set style histogram errorbars linewidth 1
#set bars front
set xlabel '% SEMI-SUPERVISED DATA'
set ylabel 'BLEU'
set xrange [-5:105]
plot '$DATA' u (\$2*100):3:4 t 'ES > EN' with yerrorbars lc 1, \
'$DATA' u (\$2*100):3 notitle w l lc 1, \
'$DATA' u (\$2*100):5:6 t 'EN > ES' with yerrorbars lc 2, \
'$DATA' u (\$2*100):5 notitle w l lc 2
EOF
} | gnuplot $PERSIST
exit 0
