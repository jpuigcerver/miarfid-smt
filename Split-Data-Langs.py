#!/usr/bin/env python
# -*- coding: utf-8 -*-

from sys import argv, exit, stderr

def SplitLangs(fname):
    try:
        fin = open(fname, 'r')
        fos = open('%s.es' % fname, 'w')
        fod = open('%s.en' % fname, 'w')
        for l in fin:
            l = l.split('#')
            src = l[0].split()
            dst = l[1].split()
            fos.write('%s\n' % ' '.join(src))
            fod.write('%s\n' % ' '.join(dst))
        fin.close()
        fos.close()
        fod.close()
        return 0
    except Exception as e:
        stderr.write('Exception: %s\n' % str(e))
        return 1

def main():
    for fname in argv[1:]:
        print 'Processing "%s"...' % fname
        r = SplitLangs(fname)
        if r != 0: return r
    return 0

if __name__ == '__main__':
    exit(main())
