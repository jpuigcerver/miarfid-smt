#!/bin/bash
set -e
export LC_NUMERIC=C

TRAIN1="data/EuTrans/training.train"
TRAIN2="data/EuTrans/training"
MERT="data/EuTrans/training.mert"
TEST="data/EuTrans/test"
LM=(2 3 4 5 6 7)
FORCE=0

function TrainMERT () {
    tr=$1
    mr=$2
    lmn=$3
    src=$4
    dst=$5
    bdir=$6
    lm=$tr.$dst.lm${lmn}
    wdir=$bdir/Work_`basename $tr`_`basename $lm`_${src}_${dst}
    echo "Training $src->$dst using \"$tr\" and a ${lmn}-gram LM" >&2;
    [ ! -f $lm -o $FORCE -eq 1 ] && { ./Create-LM.sh -d $tr.$dst -o $lmn; }
    [ ! -f $wdir/model/moses.ini -o $FORCE -eq 1 ] && {
        echo "Train phase..." >&2;
        ./Moses-Train.sh $tr $lm $lmn $src $dst $wdir
    }
    [ ! -f $wdir/mert/moses.ini -o $FORCE -eq 1 ] && {
        echo "MERT phase..." >&2;
        ./Moses-MERT.sh ${wdir} $mr.$src $mr.$dst ${wdir}/mert
    }
    echo ${wdir}/mert/moses.ini
}

function TrainTest () {
    tr=$1
    te=$2
    lmn=$3
    cfg=$4
    src=$5
    dst=$6
    bdir=$7
    lm=$tr.$dst.lm${lmn}
    wdir=$bdir/Work_`basename $tr`_`basename $lm`_${src}_${dst}
    hyp=$wdir/hyp/`basename $te`.$dst
    echo "Training $src->$dst using \"$tr\" and a ${lmn}-gram LM" >&2;
    [ ! -f $lm -o $FORCE -eq 1 ] && { ./Create-LM.sh -d $tr.$dst -o $lmn; }
    [ ! -f $wdir/model/moses.ini -o $FORCE -eq 1 ] && {
        echo "Train phase..." >&2;
        ./Moses-Train.sh $tr $lm $lmn $src $dst $wdir
    }
    [ ! -f $wdir/model/moses_updated.ini -o $FORCE -eq 1 ] && {
        echo "Update weights phase..." >&2;
        ./Update-Moses-Weights.py $wdir/model/moses.ini $cfg \
            > $wdir/model/moses_updated.ini
    }
    echo "Test phase..." >&2;
    ./Moses-Test.sh $wdir/model/moses_updated.ini $te.$src $hyp
    ./Detuplify.py < $hyp > /tmp/$$.hyp
    ./Detuplify.py < $te.$dst > /tmp/$$.ref
    ./BLEU.sh /tmp/$$.hyp /tmp/$$.ref
}

function usage () {
    cat <<-EOF >&2
Usage: $0 [OPTIONS]
Run final SMT experiments on the test data.

Options:
    -h               show this help
    -f               overwrite existing files
    -tr1 <data> ...  training data without MERT data
                     default: ${TRAIN1}
    -tr2 <data> ...  training data plus MERT data
                     default: ${TRAIN2}
    -te <n> ...      test data
                     default: ${TEST}
    -lm <n> ...      LM n-gram order
                     default: ${LM[@]}
    -mert <data>     MERT validation data
                     default: ${MERT}
EOF
}

while [ "${1:0:1}" = "-" ]; do
    case "$1" in
	"-h")
	    usage
	    exit 0
	    ;;
        "-f")
            FORCE=1; shift 1;
            ;;
	"-tr1")
            TRAIN1="$2"; shift 2;
	    ;;
	"-tr2")
            TRAIN2="$2"; shift 2;
	    ;;
	"-te")
            TEST="$2"; shift 2;
	    ;;
	"-lm")
            shift 1;
            LM=( )
            while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
                LM=( ${LM[@]} "$1" ); shift 1;
            done
	    ;;
        "-mert")
            MERT="$2"; shift 2;
            ;;
	*)
	    echo "Unknown option: \"$1\"" >&2; exit 1
    esac
done

# Separate training data
[ ! -f $TRAIN1.es -o ! -f $TRAIN1.en -o $FORCE -eq 1 ] && {
    ./Split-Data-Langs.py $TRAIN1 >&2;
}

[ ! -f $TRAIN2.es -o ! -f $TRAIN2.en -o $FORCE -eq 1 ] && {
    ./Split-Data-Langs.py $TRAIN2 >&2;
}

[ ! -f $MERT.es -o ! -f $MERT.en -o $FORCE -eq 1 ] && {
    ./Split-Data-Langs.py $MERT >&2;
}

[ ! -f $TEST.es -o ! -f $TEST.en -o $FORCE -eq 1 ] && {
    ./Split-Data-Langs.py $TEST >&2;
}

for lmn in ${LM[@]}; do
    cfg_es_en=`TrainMERT ${TRAIN1} ${MERT} $lmn es en work`
    cfg_en_es=`TrainMERT ${TRAIN1} ${MERT} $lmn en es work`
    bleu_es_en=`TrainTest ${TRAIN2} ${TEST} $lmn $cfg_es_en es en work`
    bleu_en_es=`TrainTest ${TRAIN2} ${TEST} $lmn $cfg_en_es en es work`
    echo "ES -> EN, LM: $lmn, BLEU: $bleu_es_en"
    echo "EN -> ES, LM: $lmn, BLEU: $bleu_en_es"
done
exit 0
