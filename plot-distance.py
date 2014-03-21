#!/usr/bin/env python
'''  Plots heatmap from distance matrix in plain format.'''
import sys, os
from scipy import stats
import numpy as np
from optparse import OptionParser
import matplotlib.pyplot as plt

def loadsimple(fh):
    ''' Basic one-column-header, one-row-header data table loader '''
    rh = []
    table =[]
    ch = fh.readline().rstrip().split("\t")
    del(ch[0])
    for l in fh:  
        l=l.rstrip()
        try:
            float(l.split("\t")[1]) 
            rh.append((l.split("\t")[0]))
            table.append((l.split("\t")[1:]))
        except ValueError:
            pass #headerline
    A=np.array(table, dtype="float")
    return(A, ch, rh)

if __name__ == '__main__':
    usage  = "usage: %prog -i <input sequence file> -o <output file>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--infile",  dest="infile", default=None, help="Input sequence file.")
    parser.add_option("-o", "--outfile", dest="outfile", default=None, help="Output file.")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=True, help="Verbose [default off]")
    parser.add_option("-n", "--nozero", dest="nozero", action="store_true", default=False, help="Supress zero at bottom of range")
    
    (opts, args) = parser.parse_args()
    infile = opts.infile
    if not opts.infile and args[0]: infile=args[0]
    f=open(infile)   # parse column labels
    if opts.outfile == None :  
        outfile = "%s.png"%infile
    else:
        outfile = opts.outfile
    sys.stderr.write("Processing %s, producing %s\n" % (infile, outfile) )  
    (A, ch, rh) = loadsimple(f)
    if opts.nozero:
        vmin = None
    else:
        vmin = 0
    plt.imshow(A, interpolation="nearest", aspect="auto", vmin=vmin )
    plt.title(infile)
    if A.shape[1] == 45 and A.shape[0] == 45 :
        pos = np.arange(float(A.shape[1])/5) * 5 + 2.5
        plt.yticks(pos, ('C', 'Ch1', 'Ch2', 'Ch3','Ch4', 'Ch5', 'E1', 'R', 'W') )
        plt.xticks(pos, ('C', 'Ch1', 'Ch2', 'Ch3','Ch4', 'Ch5', 'E1', 'R', 'W') )
    if A.shape[1] == 10:
        pos = np.arange(A.shape[1])
        plt.yticks(pos, tuple(rh) )
        plt.xticks(pos, tuple(rh) )
    plt.colorbar()
    plt.savefig(outfile)
  #  plt.show()
