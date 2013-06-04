#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sys import argv, stderr

def ParseMertCfg(fname):
    WD, WL, WT, WP = [], [], [], []
    f = open(fname, 'r')
    cw = None
    for l in f:
        l = l.strip()
        if l == '[weight-d]':
            cw = WD
        elif l == '[weight-l]':
            cw = WL
        elif l == '[weight-t]':
            cw = WT
        elif l == '[weight-w]':
            cw = WP
        elif l == '':
            cw = None
        elif cw is not None:
            cw.append(l)
    f.close()
    return WD, WL, WT, WP

def UpdateMosesModel(fname, WD, WL, WT, WP):
    # Reverse weights lists to use pop()
    WD.reverse()
    WL.reverse()
    WT.reverse()
    WP.reverse()
    # Parse original model file and update weights
    f = open(fname, 'r')
    cw = None
    for l in f:
        l = l.strip()
        l = l.strip()
        if l == '[weight-d]':
            cw = WD
            print l
        elif l == '[weight-l]':
            cw = WL
            print l
        elif l == '[weight-t]':
            cw = WT
            print l
        elif l == '[weight-w]':
            cw = WP
            print l
        elif l == '':
            cw = None
            print l
        elif cw is not None:
            print cw.pop()
        else:
            print l
    f.close()

if len(argv) != 3:
    stderr.write('Usage: %s <init_model> <mert_model>\n' % argv[0])
    exit(1)

WD, WL, WT, WP = ParseMertCfg(argv[2])
UpdateMosesModel(argv[1], WD, WL, WT, WP)
exit(0)
