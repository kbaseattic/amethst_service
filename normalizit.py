#!/usr/bin/env python

import sys, os
from scipy import stats
import numpy as np
from optparse import OptionParser

def readwithheaders(f):
  '''reads file with one column of headers and one row of headers'''
  phyla =[]
  table =[]
  firstline=1
  for l in f:
    if firstline==0:
      l=l.rstrip()
      phyla.append((l.split("\t")[0]))
      table.append((l.split("\t")[1:]))
    else:
      samplenames = l.rstrip().split("\t")
      if samplenames[0][0] == "#":
        samplenames[0] = samplenames[0][1:]
    firstline=0
  del(samplenames[0])
  return(phyla,table,samplenames)

if __name__ == '__main__':
  usage  = "usage: %prog -i <input sequence file> \n outputs to standard out"
  parser = OptionParser(usage)
  parser.add_option("-i", "--input",  dest="infile", default=None, help="Input sequence file.")
  parser.add_option("-m", "--method",  dest="method", default="simplex", help="Method (simplex, log2norm, mgr, simprowwise, rowwise)")
  parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=True, help="Verbose [default off]")
  parser.add_option("-c", "--mincounts", dest="mincounts", default=0, help="Minimum counts per row (set to 2 to remove singletons)")
  
  (opts, args) = parser.parse_args()
  filename=opts.infile
  mincounts=int(opts.mincounts)
  if not opts.infile and args[0]:
    filename=args[0]
  f=open(filename)   # parse column labels
  (phyla, table,samplenames)=readwithheaders(f)

  A=np.array(table, dtype="int")
  A1=A
  if opts.method == "simplex" or opts.method == "simprowwise" :
      A1 = ((A.astype("float") / np.sum(A.T,axis=1)).T).T        # divide by the sum of each column.
  if opts.method == "simprowwise" or opts.method == "rowwise"  :
      A1  =  (A1.T.astype("float") / np.sum(A1, axis=1) ).T       # divide by the sum of each row.
  if opts.method =="log2norm" or opts.method=="log2normscaled" :
      A00 = np.log(A.astype("float")+1) 
      A0 = ((A00.astype("float")   - np.mean(A00.T,axis=1)).T).T # subtract the mean of each column.
      A1 = ((A0 / np.std(A0.T,axis=1)).T).T                      # divide by the stddev of each column 
  if opts.method =="log2normscaled":
      A1 = (A1 - np.min(A1) )  / (np.max(A1) - np.min(A1) )      # subtract and divide global max, min
  if opts.method=="mgr": 
      A00 = np.log(A.astype("float")+1) 
      A1 = ( A00.astype("float") - np.mean(A00) ) / np.std(A00)  # subtract and divide global mean, std 
      A1 = (A1 - np.min(A1) )  / (np.max(A1) - np.min(A1) )      # subtract and divide global max, min

  # output data table
  print "#Data\t"+"\t".join(samplenames)
  for i in range(0, len(phyla)):
      if np.sum(A[i,:] ) >= mincounts :
          print phyla[i]+"\t",
          print "\t".join(map(str,A1[i,:]))

