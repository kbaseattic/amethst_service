#!/usr/bin/env python

import sys, os
from scipy import stats
import numpy as np
from optparse import OptionParser
import matplotlib.pyplot as plt
import re
def parsegroupsfile(filename):
  f=open(filename)  
  i=1
  name=[]
  grouplist = {}
  for l in f:
    groupname="Group%02d"%i
    name.append(groupname)
    grouplist[groupname] = l.rstrip().split(",")   
    i+=1
  print grouplist
  return grouplist
def parsefile(f):
  eigenvalues={}
  eigenvectors={}
  samplelabels=[]
  EIGENVALUES =0
  EIGENVECTORS =0
  for l in f:  
     l=l.rstrip()
     b=re.search("EIGEN VALUES" , l)
     try: 
         len(b.groups()) > 0
         EIGENVALUES =1 
     except AttributeError:
         pass
     b=re.search("EIGEN VECTORS" , l)
     try: 
         len(b.groups()) > 0
         EIGENVALUES =0 
         EIGENVECTORS =1 
     except AttributeError:
         pass
     if l[0] !="#":
      a=re.search("\"PCO(\d*)\"\t([\d.]*)", l)
      try:
         len(a.groups()) > 0 
         a1 = int(a.groups()[0])-1
         a2 = float(a.groups()[1])
         eigenvalues[a1] = a2 
      except AttributeError: 
         pass
      if EIGENVECTORS==1:
         fields = l.split("\t")
#         print "EIGENVECTORS: ", fields
         if fields[0][0]=="\"" : fields[0]=fields[0][1:]
         if fields[0][-1]=="\"" : fields[0]=fields[0][:-1]
         samplelabels.append(fields[0])
         eigenvectors[fields[0]] = fields[1:]
  return eigenvectors, eigenvalues, samplelabels

if __name__ == '__main__':
  usage  = "usage: %prog -i <input sequence file> -o <output file>"
  parser = OptionParser(usage)
  parser.add_option("-i", "--input",  dest="infile", default=None, help="Input sequence file.")
  parser.add_option("-o", "--output",  dest="outfile", default=None, help="Output image filename")
  parser.add_option("-g", "--groups", dest="groups", default=None, help="Groups file")
  parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=True, help="Verbose [default off]")
  parser.add_option("-l", "--labels", dest="labels", default=None, help="Comma delimited group labels")
  
  (opts, args) = parser.parse_args()
  infile = opts.infile
  outfile = opts.outfile
  groupsfile = opts.groups
  groups = parsegroupsfile(groupsfile)
  if not opts.infile and args[0]: infile=args[0]
  f=open(infile)   # parse column labels
  (eigenvectors, eigenvalues, samplelabels)=parsefile(f)     # rely on global variables
  x=range(len(samplelabels))
  i=0
  for g in sorted(groups.keys()):
    if g !="Group06":
     a = [ float(eigenvectors[s][0])*eigenvalues[0]  for s in groups[g] ] 
     b = [ float(eigenvectors[s][1])*eigenvalues[1]  for s in groups[g] ]   
     print a 
     print b
     if opts.labels == None:
       label = g
     else :
       label=opts.labels.split(",")[i] 
     plt.plot(a ,b , '.', markersize=15, label=label) 
     plt.axes().set_aspect('equal' )
     plt.axes().set_aspect('auto' )
     plt.xlabel("PC 1 (%.1f%%)"%(eigenvalues[0]*100) ) 
     plt.ylabel("PC 2 (%.1f%%)"%(eigenvalues[1]*100) ) 
     plt.title(infile)
     plt.grid(1)
    i+=1
  plt.legend(numpoints=1, loc="lower center")
  if opts.outfile==None:
    plt.show()
  else:
    plt.savefig(outfile)
