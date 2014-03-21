#!/usr/bin/env python
'''Script to extract average distances from AMETHST output and produce simple table, outputs to std out'''
import sys, os
from scipy import stats
import numpy as np
from optparse import OptionParser
import re

if __name__ == '__main__':
    usage  = "usage: %prog -i <input sequence file>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input",  dest="infile", default=None, help="Input sequence file.")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=True, help="Verbose [default off]")
    
    (opts, args) = parser.parse_args()
    infile = opts.infile
    if not opts.infile and args[0]: infile=args[0]
    f=open(infile)   # parse column labels
  
    h=  {} 
    phyla =[]
    table =[]
    samplenames0 = f.readline().split("\t")  
    index = {}
    index[0] = ""
    NUMBINS=0
    for l in f:  
        l=l.rstrip()
        try:
            l[0] 
        except IndexError:
            l="#"
    
        if l[0] != "#" :
            b=re.search("mean_Group\((\d*)\)\t([\d.]*)" , l)
            try: 
               if(len(b.groups()) > 0):
                 a1 = int(b.groups()[0])-1
                 a6 = b.groups()[1]
                 h[(int(a1),int(a1))] = a6 
      #           print "winner", a1
                 index[a1] = "Group %d"%a1
                 NUMBINS +=1
            except AttributeError:
               pass
            a=re.search("mean_Group\((\d*)\)::Group\((\d*)\)\t([\d.]*)\tstdev\t([\d.]*)", l)
            try:
                len(a.groups()) > 0 
                a1 = int(a.groups()[0])-1
                a2 = int(a.groups()[1])-1
                a3 = a.groups()[2]
                h[(int(a1),int(a2))] = a3
                h[(int(a2),int(a1))] = a3
            except AttributeError: 
                pass
  #  print h
  #  print index
    labels = [str(i+1) for i in range(0, NUMBINS) ]
    labels = [index[i] for i in range(0, NUMBINS) ]
    print "#Pvalues\t", "\t".join(labels)
    for i in range(0,NUMBINS):
        print labels[i]+"\t"+"\t".join( "%.05f"%m for m in (map(float, (h[(i,j)] for j in range(NUMBINS) ))))
