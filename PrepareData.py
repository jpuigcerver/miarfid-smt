#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sys import argv, exit, stderr

def NGramLine(line, n):
    prev_w = [ '' for i in range(n-1) ]
    res = []
    for w in line:
        res.append('_'.join(prev_w) + '_' + w)
        prev_w = prev_w[1:]
        prev_w.append(w)
    return res

def PrepareNGrams(fname, n):
    try:
        fin = open(fname, 'r')
        fout = open('%s.%dgram' % (fname, n), 'w')
        for l in fin:
            l = l.split('#')
            if len(l) != 2: continue
            src = l[0].split()
            dst = l[1].split()
            src_n = NGramLine(src, n)
            dst_n = NGramLine(dst, n)
            out_line = '%s # %s' % (' '.join(src_n), ' '.join(dst_n))
            fout.write('%s\n' % out_line)
        fin.close()
        fout.close()
    except Exception as e:
        stderr.write('Exception: %s\n' % str(e))
        return 1

def main():
    for fname in argv[1:]:
        print fname
        r = PrepareNGrams(fname, 2)
        if r != 0: return r
        r = PrepareNGrams(fname, 3)
        if r != 0: return r
    return 0

if __name__ == '__main__':
    exit(main())
