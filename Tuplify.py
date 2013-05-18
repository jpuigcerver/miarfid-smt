#!/usr/bin/env python
# -*- coding: utf-8 -*-
from sys import argv

def tuplify(sent, n):
    wrd = [ '' for i in range(n-1)  ]
    out_sent = []
    for w in sent:
        wrd.append(w)
        out_sent.append('_'.join(wrd))
        wrd = wrd[1:]
    return ' '.join(out_sent)

N = int(argv[1])
for fname in argv[2:]:
    print 'Processing "%s"...' % fname
    fin = open(fname, 'r')
    fout = open('%s.%dwords' % (fname, N), 'w')
    for l in fin:
        l = l.split('#')
        if len(l) != 2: continue
        src_sent = tuplify(l[0].split(), N)
        dst_sent = tuplify(l[1].split(), N)
        fout.write('%s # %s\n' % (src_sent, dst_sent))
    fin.close()
    fout.close()
