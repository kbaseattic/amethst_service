#!/usr/bin/env python
'''Generates artificial count-like data in groups.'''

import sys
from scipy import stats
import numpy as np
from optparse import OptionParser
GROUPSFILE = "groups.csv"

def printtable(tablefile, taxonlist, d):
    '''print fake abundance table'''
    tbl_fh = open(tablefile, "w")
    tbl_fh.write("Phylum\t")  
    for i in range(0, NSAMPLES):
        tbl_fh.write("R_%.04d" % i)
        if i < NSAMPLES - 1:
            tbl_fh.write("\t")
    tbl_fh.write("\n")
    for i in range(0, d.shape[1]):
        tbl_fh.write(taxonlist[i] + "\t" + "\t".join(
            "%d" % float(value) for value in d[:, i]) + "\n")

def printgroups(GROUPSFILE, ngroups, replicates):
    '''print groups table'''
    groups_out_fh = open(GROUPSFILE, "w")  
    for i in range(0, ngroups):
        grouplist = ["R_%.04d" % (i * replicates + j)
                     for j in range(replicates)]
        print grouplist
        groups_out_fh.write(",".join(grouplist) + "\n")

def readfirstcolumn(filename):
    '''returns array of column headers'''
    f = open(filename)  
    taxonlist = []
    for l in f:
        if l[0] != "#":
            taxonlist.append(l.split("\t")[0])
    return(taxonlist)

if __name__ == '__main__':
    usage = "usage:  fake-countdata.py [options] -o <outputfile>\npurpose:  generates fake counts data from a number of distributions"
    parser = OptionParser(usage)
    parser.add_option( "-o", "--output", dest="output", default="table.csv", help="Output file.")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true",
                      default=True, help="Verbose [default off]")
    parser.add_option("-m", "--model", dest="model", default="nbinom",
                      help="Taxon model: nbinom(default), uniform, even")
    parser.add_option("-s", "--samplingmodel", dest="samplingmodel", default="poisson",
                      help="Sampling model: poisson(default), uniform")
    parser.add_option("-g", "--groupdiff", dest="groupdiff", default=None, 
                   help="Comma-separated group differences (default all=1.0=no diff)")
    parser.add_option("-r", "--replicates", dest="replicates",
                      default=10, help="Number of samples per group")
    parser.add_option( "-n", "--ngroups", dest="ngroups", default=2, help="Number of groups")
    parser.add_option("-t", "--taxonfile", dest="taxonfile", default="taxonlist.csv", 
                help="File containing taxon headings in first column")

    (opts, args) = parser.parse_args()
    NGROUPS = int(opts.ngroups)
    REPLICATES = int(opts.replicates)
    NSAMPLES = NGROUPS * REPLICATES
    TAXONLIST = opts.taxonfile
    if not opts.output:
        sys.exit("-o outputfile is a mandatory parameter")
    if opts.groupdiff == None:
        groupdiff = np.ones(NGROUPS)
    else:
        groupdiff = map(float, opts.groupdiff.split(","))
    print "Groupdiff", groupdiff
    TABLEFILE = opts.output
#   parse column labels only
    taxonlist = readfirstcolumn(TAXONLIST)

#   generate one abundance level per taxon, a:
    if opts.model == "nbinom":
        a = 100 * stats.gamma.rvs(.3, .03, size=len(taxonlist))  
#   uniform exposures
    if opts.model == "uniform":
        a = 5000 * stats.uniform.rvs(0, 1, size=len(taxonlist))  
    if opts.model == "even":
        a = np.ones((1, len(taxonlist)))[0] * 5000
    modifier = []
#   now generate one abundance level per taxon per group:
    for i in range(NGROUPS):
#        multiplicative factor to make groups distinct
        groupmodifier = stats.gamma.rvs(1 / groupdiff[i], size=len(taxonlist)) * groupdiff[i]    
        for j in range(REPLICATES):
#           and populate a full-sized array with these near-one multiplicative modifiers
            modifier.append(groupmodifier)
#   and convert to full-sized numpy array 
    modifier = np.array(modifier)

    for i in range(len(a)):
        # necessary because poisson does not accept 0 in its range
        if a[i] == 0:
            a[i] = 1E-8  
    for i in range(0, NSAMPLES):   # generate
        if opts.samplingmodel == "poisson" : 
            b = stats.poisson.rvs(a * modifier)
        elif opts.samplingmodel == "uniform" : 
            b = stats.uniform.rvs(size=(np.shape(modifier)))  *( a*modifier)
        elif opts.samplingmodel == "even" : 
            b = a*modifier
        else : 
            assert False # print "unrecognized sampling model"
    c = b
    d = np.array(c, dtype="int") 

    printtable(TABLEFILE, taxonlist, d)
    printgroups(GROUPSFILE, NGROUPS, REPLICATES)

