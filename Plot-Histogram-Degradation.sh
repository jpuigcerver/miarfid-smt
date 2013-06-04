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
        ;;
    ps)
        OUTPUT="set output '$DATA.ps'"
        PERSIST=
        ;;
    x11)
        OUTPUT=
        PERSIST="-persist"
        ;;
    *)
        echo "Unknown format: $FORMAT" >&2; exit 1
esac

{
    cat <<EOF
set term $FORMAT
$OUTPUT
set style data histogram
set style histogram errorbars linewidth 1
set bars front
set xlabel 'ROUNDS'
set ylabel 'BLEU'
plot '$DATA' u 3:(\$3-\$4):(\$3+\$4):xticlabels(2) t 'ES > ES', \
'$DATA' u 5:(\$5-\$6):(\$5+\$6):xticlabels(2) t 'EN > EN'
EOF
} | gnuplot $PERSIST
exit 0
