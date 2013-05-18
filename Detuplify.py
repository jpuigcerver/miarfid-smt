#!/usr/bin/env python
# -*- coding: utf-8 -*-
from sys import stdin

for l in stdin:
    l = l.split()
    s = []
    for t in l:
        t = t.split('_')
        s.append(t[-1])
    print ' '.join(s)
