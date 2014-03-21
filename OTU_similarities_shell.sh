#!/bin/bash
# written 7-31-12
# revised 4-23-13

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -ne 7 ] # usage and exit if 2 args are not supplied

then
    echo
    echo "USAGE: >OTU_similarities_shell.sh <data_file> <OTU_DIST_output_type>"
    echo   
    echo "     <file_in>         : file name, name of the input data file (don't type quotes):" 
    echo "                                 tab delimited table," 
    echo "                                 columns = metagenomes,"
    echo "                                 rows = abundance counts for given type and level (e.g. subsystem level 2) " 
    echo "     <input_dir>       : (string)  directory that contains file_in"
    echo "     <output_PCoA_dir> : (string)  directory for the output *.PCoA file"
    echo "     <print_dist>      : (boolean) [ 1 | 0 ] print distance matrices"
    echo "     <output_DIST_dir> : (string)  directory for the output *.DIST files"
    echo "     <dist_method>     : (string), one of two output types"
    echo "                                 \"OTU\"   - simple OTU overlap" 
    echo "                                 \"w_OTU\" - abundance weighted OTU overlap"
    echo "     <headers>         : (boolean) [ 1 | 0 ] print headers in the PCoA output files"
    echo
    echo " # Script produces *.DIST and *.PCoA outputs using the specified OTU method"
    echo
    exit 1                                                                                          # exit the script
fi

time_stamp=`date +%m-%d-%y_%H:%M:%S:%N`;  # create the time stamp month-day-year_hour:min:sec:nanosec

echo "# shell generated script to run OTU_similarities.kpk_edit.7-30-12.r" >> do_OTU.$time_stamp.r
echo "# time stamp; $time_stamp" >> do_OTU.$time_stamp.r
echo "source(\"$DIR/OTU_similarities.r\")" >> do_OTU.$time_stamp.r       
echo "OTU_dists(file_in = \"$1\", input_dir = \"$2\", output_PCoA_dir = \"$3\", print_dist = $4, output_DIST_dir = \"$5\" , dist_method = \"$6\", headers = $7)" >> do_OTU.$time_stamp.r

R --vanilla --slave < do_OTU.$time_stamp.r
rm do_OTU.$time_stamp.r
