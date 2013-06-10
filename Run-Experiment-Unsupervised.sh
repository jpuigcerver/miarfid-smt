#!/bin/bash
set -e
export LC_NUMERIC=C
TRAIN=( `ls data/EuTrans/training.train.train[0-9][0-9]` )
VALID=( `ls data/EuTrans/training.train.valid[0-9][0-9]` )
MERT="data/EuTrans/training.mert"
LM=( 2 3 4 5 6 7 )
UNS=( 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 )
FORCE=0

function TrainMertTest {
    tr=$1
    va=$2
    lmn=$3
    mert=$4
    src=$5
    dst=$6
    lm=$tr.$dst.lm${lmn}
    wdir=$7/Work_Unsupervised_`basename $tr`_lmn${lmn}/${src}_${dst}
    hyp=$wdir/hyp/`basename $va`.$dst
    [ ! -f $lm -o $FORCE -eq 1 ] && { ./Create-LM.sh -d $tr.$dst -o $lmn; }
    [ ! -f $wdir/model/moses.ini -o $FORCE -eq 1 ] && {
        echo "Train phase..." >&2;
        ./Moses-Train.sh $tr $lm $lmn $src $dst $wdir
    }
    [ ! -f $wdir/mert/moses.ini -o $FORCE -eq 1 ] && {
        echo "MERT phase..." >&2;
        ./Moses-MERT.sh $wdir $mert.$src $mert.$dst ${wdir}/mert
    }
    [ ! -f $hyp -o $FORCE -eq 1 ] && {
        echo "Test phase..." >&2;
        ./Moses-Test.sh $wdir/mert/moses.ini $va.$src $hyp
    }
    ./Detuplify.py < $hyp > /tmp/$$.hyp
    ./Detuplify.py < $va.$dst > /tmp/$$.ref
    ./BLEU.sh /tmp/$$.hyp /tmp/$$.ref
}

function TrainMertTestUnsupervised {
    tr=$1
    va=$2
    lmn=$3
    mert=$4
    src=$5
    dst=$6
    uns=$7
    bdir=$8
    lm=$tr.$dst.lm${lmn}
    tr_sup_uns=${tr}.sup+uns${uns}_${src}_${dst}
    # Prepare new training data including unsupervised target data
    # new source data is assumed to be supervised
    [ ! -f $tr_sup_uns.$src -o ! -f $tr_sup_uns.$dst -o $FORCE -eq 1 ] && {
        echo "Preparing unsupervised data..." >&2;
        wdir=${bdir}/Work_Unsupervised_`basename $tr.sup`_lmn${lmn}/${src}_${dst}
        uns_src=${tr}.uns${uns}.${src}
        uns_dst=${wdir}/hyp/`basename ${uns_src}`
        ./Moses-Test.sh ${wdir}/mert/moses.ini ${uns_src} ${uns_dst}
        cat ${tr}.sup.${src} ${uns_src} > ${tr_sup_uns}.${src}
        cat ${tr}.sup.${dst} ${uns_dst} > ${tr_sup_uns}.${dst}
    }
    TrainMertTest $tr_sup_uns $va $lmn $mert $src $dst $8
}

function help () {
    cat <<-EOF >&2
Usage: $0 [OPTIONS]
Run SMT experiments using validation data.

Options:
    -h               show this help
    -f               overwrite existing files
    -tr <data> ...   training data
                     default: ${TRAIN[@]}
    -va <n> ...      validation data
                     default: ${VALID[@]}
    -lm <n> ...      LM n-gram order
                     default: ${LM[@]}
    -mert <data>     MERT validation data
                     default: ${MERT}
    -uns <f> ...     fraction of unsupervised data to use
                     default: ${UNS[@]}
EOF
}

while [ "${1:0:1}" = "-" ]; do
    case "$1" in
	"-h")
	    help
	    exit 0
	    ;;
        "-f")
            FORCE=1; shift 1;
            ;;
	"-tr")
            shift 1;
            TRAIN=( )
            while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
                TRAIN=( ${TRAIN[@]} "$1" ); shift 1;
            done
	    ;;
	"-va")
            shift 1;
            VALID=( )
            while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
                VALID=( ${VALID[@]} "$1" ); shift 1;
            done
	    ;;
	"-lm")
            shift 1;
            LM=( )
            while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
                LM=( ${LM[@]} "$1" ); shift 1;
            done
	    ;;
        "-uns")
            shift 1;
            UNS=( )
            while [ "${1:0:1}" != "-" -a $# -gt 0 ]; do
                UNS=( ${UNS[@]} "$1" ); shift 1;
            done
            ;;
        "-mert")
            MERT="$2"; shift 2;
            ;;
	*)
	    echo "Unknown option: \"$1\"" >&2; exit 1
    esac
done

[ ${#TRAIN[@]} -lt 1 ] && {
    echo "Expected training data. Use -tr and -va options." >&2;
    exit 1;
}
[ ${#TRAIN[@]} -ne ${#VALID[@]} ] && {
    echo "Training data and validation data mismatch." >&2;
    exit 1;
}
[ ${#LM[@]} -lt 1 ] && {
    echo "At least one LM needed. Use -lm option." >&2;
    exit 1;
}

mert_en=$MERT.en
mert_es=$MERT.es
[ ! -f $mert_es -o ! -f $mert_en ] && {
    ./Split-Data-Langs.py $MERT >&2;
}

# Prepare basic supervised data
NDATA=${#TRAIN[@]}
for n in `seq 0 $[$NDATA - 1]`; do
    tr=${TRAIN[n]}
    NTOT=`cat $tr | wc -l`
    NSUP=`python -c "print int($NTOT * 0.5)"`
    head -n $NSUP $tr > $tr.sup
    [ ! -f $va.es -o ! -f $va.en ] && {
        ./Split-Data-Langs.py $va >&2;
    }
done

for lmn in ${LM[@]}; do
    # Prepare ONLY-supervised models
    sum_err1=0.0; sum_err2=0.0;
    sum_sq_err1=0.0; sum_sq_err2=0.0;
    for n in `seq 0 $[$NDATA - 1]`; do
        tr=${TRAIN[n]}.sup
        va=${VALID[n]}
        [ ! -f $tr.es -o ! -f $tr.en ] && {
            ./Split-Data-Langs.py $tr >&2;
        }
        # ES -> EN
	echo "Training ES->EN using \"$tr\" and a ${lmn}-gram LM" >&2;
        err1=`TrainMertTest $tr $va $lmn $MERT es en work`
        # EN -> ES
	echo "Training EN->ES using \"$tr\" and a ${lmn}-gram LM" >&2;
        err2=`TrainMertTest $tr $va $lmn $MERT en es work`
        sum_err1=$(echo "$sum_err1 + $err1" | bc -l)
        sum_err2=$(echo "$sum_err2 + $err2" | bc -l)
        sum_sq_err1=$(echo "$sum_sq_err1 + $err1 * $err1" | bc -l)
        sum_sq_err2=$(echo "$sum_sq_err2 + $err2 * $err2" | bc -l)
    done
    avg_err1=$(echo "$sum_err1 / $NDATA" | bc -l)
    avg_err2=$(echo "$sum_err2 / $NDATA" | bc -l)
    std_err1=$(echo "sqrt($sum_sq_err1 / $NDATA - $avg_err1 * $avg_err1)" | \
        bc -l)
    std_err2=$(echo "sqrt($sum_sq_err2 / $NDATA - $avg_err2 * $avg_err2)" | \
        bc -l)
    ci_err1=$(echo "1.96 * $std_err1 / sqrt($NDATA)" | bc -l)
    ci_err2=$(echo "1.96 * $std_err2 / sqrt($NDATA)" | bc -l)
    printf "%d 0.0 %f %f %f %f\n" $lmn $avg_err1 $ci_err1 $avg_err2 $ci_err2
    #### RESULTS using additional unsupervised data
    for uns in ${UNS[@]}; do
        sum_err1=0.0; sum_err2=0.0;
        sum_sq_err1=0.0; sum_sq_err2=0.0;
        for n in `seq 0 $[$NDATA - 1]`; do
            tr=${TRAIN[n]}
            va=${VALID[n]}
            NSUP=`cat $tr.sup | wc -l`
            NUNS=`python -c "print int($NSUP * $uns)"`
            tail -n +$[NSUP+1] $tr | head -n $NUNS > $tr.uns$uns
            # Separate training and validation data into two languages
            [ ! -f $tr.uns$uns.es -o ! -f $tr.uns$uns.en ] && {
                ./Split-Data-Langs.py $tr.uns$uns >&2;
            }

            # ES -> EN
	    echo "Training ES->EN using \"$tr\" + unsupervised ($uns) and a ${lmn}-gram LM" >&2;
            err1=`TrainMertTestUnsupervised $tr $va $lmn $MERT es en $uns work`
            # EN -> ES
	    echo "Training EN->ES using \"$tr\" + unsupervised ($uns) and a ${lmn}-gram LM" >&2;
            err2=`TrainMertTestUnsupervised $tr $va $lmn $MERT en es $uns work`
            sum_err1=$(echo "$sum_err1 + $err1" | bc -l)
            sum_err2=$(echo "$sum_err2 + $err2" | bc -l)
            sum_sq_err1=$(echo "$sum_sq_err1 + $err1 * $err1" | bc -l)
            sum_sq_err2=$(echo "$sum_sq_err2 + $err2 * $err2" | bc -l)
        done
        avg_err1=$(echo "$sum_err1 / $NDATA" | bc -l)
        avg_err2=$(echo "$sum_err2 / $NDATA" | bc -l)
        std_err1=$(echo "sqrt($sum_sq_err1 / $NDATA - $avg_err1 * $avg_err1)" | \
            bc -l)
        std_err2=$(echo "sqrt($sum_sq_err2 / $NDATA - $avg_err2 * $avg_err2)" | \
            bc -l)
        ci_err1=$(echo "1.96 * $std_err1 / sqrt($NDATA)" | bc -l)
        ci_err2=$(echo "1.96 * $std_err2 / sqrt($NDATA)" | bc -l)
        printf "%d %f %f %f %f %f\n" $lmn $uns $avg_err1 $ci_err1 $avg_err2 $ci_err2
    done
done
exit 0
