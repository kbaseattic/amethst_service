#!/bin/bash
infile=$1
if [ ! -e $infile ]
then
echo "No $infile ??"
exit
fi
if [ ! -e $infile.groups ]
then
echo "No $infile.groups ??"
exit
fi

type=$2
if [ "$type" = "" ]
then
type=rowwise_rand
fi

method=euclidean
prefix=plot_pco_with_stats.
dirpostfix=.$method.RESULTS
analysisdir=$prefix$infile$dirpostfix
finalanalysisdir=$prefix$infile.$method.$type.RESULTS

# example scripts to invoke plot_pco_with_stats and visualize the output
if [ ! -e $analysisdir/$infile.png ]
then
echo generating directory $analysisdir with 
echo plot_pco_with_stats.9-18-12.pl --data_file $infile  --groups_list $infile.groups --num_perm 100 --dist_method $method --perm_type=$type
     plot_pco_with_stats.9-18-12.pl --data_file $infile  --groups_list $infile.groups --num_perm 100 --dist_method $method --perm_type=$type 2>error.log 
fi 

echo plotting heatmap of original data
echo plot-distance.py -i $infile -o $analysisdir/$infile.png 
     plot-distance.py -i $infile -o $analysisdir/$infile.png 

echo generating heatmap of distances in $prefix.$infile$dirpostfix/$infile.$method.DIST.png with 
echo plot-distance.py -i $analysisdir/$infile.$method.DIST
     plot-distance.py -i $analysisdir/$infile.$method.DIST

echo parse-avgdistance.py  $analysisdir/$infile.$method.DIST.AVG_DIST  $analysisdir/$infile.$method.DIST.AVG_DIST.csv
     parse-avgdistance.py  $analysisdir/$infile.$method.DIST.AVG_DIST > $analysisdir/$infile.$method.DIST.AVG_DIST.csv

echo plot-distance.py -i $analysisdir/$infile.$method.DIST.AVG_DIST.csv
     plot-distance.py -i $analysisdir/$infile.$method.DIST.AVG_DIST.csv


echo generating all-against-all p-value table in $analysisdir/$infile.$method.P_VALUES_SUMMARY.csv:
echo parse-pvalues.py -i $analysisdir/$infile.$method.P_VALUES_SUMMARY  
     parse-pvalues.py -i $analysisdir/$infile.$method.P_VALUES_SUMMARY  > $analysisdir/$infile.$method.P_VALUES_SUMMARY.csv

echo generating heatmap of p-values in $analysisdir/$infile.$method.P_VALUES_SUMMARY.csv.png
echo plot-distance.py -i $analysisdir/$infile.$method.P_VALUES_SUMMARY.csv
     plot-distance.py -i $analysisdir/$infile.$method.P_VALUES_SUMMARY.csv

echo generating PCOA plot in $analysisdir/$infile.$method.PCoA.png
echo parse-pcoa.py -i   $analysisdir/$infile.$method.PCoA -g $infile.groups  -o $analysisdir/$infile.$method.PCoA.png 
     parse-pcoa.py -i   $analysisdir/$infile.$method.PCoA -g $infile.groups  -o $analysisdir/$infile.$method.PCoA.png 

echo plotting one of the permutations
plot-distance.py -i $analysisdir/permutations/$infile.permutation.1 -o $analysisdir/$infile.permutation.1.png

mv $analysisdir $finalanalysisdir
mv $infile.plot_pco_with_stats.log $infile.$method.$type.plot_pco_with_stats.log
