#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sys import argv, stderr, stdout
from math import sqrt

def ParseList(i = 0):
    l = []
    while i < len(argv) and argv[i][0] != "-":
        l.append(argv[i])
        i = i + 1
    return i, l

def LoadFile(fname):
    f = open(fname, 'r')
    V, P = set(), []
    for l in f:
        l = l.split()
        P.append(l)
        V.update(l)
    f.close()
    return V, P

REF, TRA = [], []
i = 1
while i < len(argv):
    if argv[i] == '-tra':
        i, TRA = ParseList(i + 1)
    elif argv[i] == '-ref':
        i, REF = ParseList(i + 1)
    elif argv[i] == '-voc':
        i, VOC = ParseList(i + 1)
    elif argv[i] == '-h':
        stdout.write("""Usage: %s -tra training... -ref references...
Compute the average OOV words from a set of files.
""" % argv[0])
        exit(0)
    else:
        stderr.write('Unknown option: %s\n' % argv[i])
        exit(1)

if len(TRA) != len(REF):
    stderr.write('The number of training files and references must be equal.\n')
    exit(1)

sum_oov, sum_sq_oov = 0, 0
sum_oov2, sum_sq_oov2 = 0, 0
for i in range(0, len(TRA)):
    VT, PT = LoadFile(TRA[i])
    VR, PR = LoadFile(REF[i])
    N = len(PR)
    # Number of total OOV respect
    # the number of words in the reference
    oov1, nw = 0, 0
    for j in range(0, N):
        for w in PR[j]:
            if w not in VT:
                oov1 = oov1 + 1
        nw = nw + len(PR[j])
    oov1 = float(oov1) / float(nw)
    # Number of OOV words in the training
    # vocabulary
    oov2 = 0
    for w in VR:
        if w not in VT:
            oov2 = oov2 + 1
    oov2 = float(oov2) / float(len(VT))
    sum_oov = sum_oov + oov1
    sum_sq_oov = sum_sq_oov + oov1 * oov1
    sum_oov2 = sum_oov2 + oov2
    sum_sq_oov2 = sum_sq_oov2 + oov2 * oov2
    print oov1, oov2
avg_oov1 = sum_oov / len(TRA)
var_oov1 = sum_sq_oov / len(TRA) - avg_oov1 * avg_oov1
icf_oov1 = 1.96 * sqrt(var_oov1 / len(TRA))

avg_oov2 = sum_oov2 / len(TRA)
var_oov2 = sum_sq_oov2 / len(TRA) - avg_oov2 * avg_oov2
icf_oov2 = 1.96 * sqrt(var_oov2 / len(TRA))
print 'MEAN OOV1 = %f [+/- %f], MEAN OOV2 = %f [+/- %f]' % (
    avg_oov1 * 100, icf_oov1 * 100,
    avg_oov2 * 100, icf_oov2 * 100)
exit(0)
