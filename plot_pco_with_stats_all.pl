#!/usr/bin/env perl

# Adapted from 11-21-12 version, for use with master that can call
# plot_pco_with_stats,
# plot_qiime_pco_with_stats, or
# plot_OTU_pco_with_stats

#use strict;
use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
use FindBin;
use File::Basename;

my $start = time;

my($data_file, $cleanup, $help, $verbose, $debug, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir);

my $output_prefix = "NA";
my $job_name = "job";
my $current_dir = getcwd()."/";
my $perm_dir = "default";
#if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

#define defaults for variables that need them
my $groups_list = "groups_list";
my $sig_if = "lt";
my $dist_pipe = "MG-RAST_pipe";
my $qiime_format = "biom"; # qiime_table R_table
my $input_dir = $current_dir;
my $create_perm_pcoas = 1; # controlled below by $cleanup
my $print_dist = 1;
my $dist_list = "DISTs_list";
my $dist_method = "euclidean";
my $tree = "NO DEFAULT";  
my $avg_dists_list = "AVG_DISTs_list";
my $headers = 1; 
my $perm_list = "permutation_list" ;
my $perm_type = "dataset_rand";
my $num_perm = 10;
my $num_cpus = 1;
my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;

#my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles
my $DIR="$FindBin::Bin/";


# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $data_file ) { &usage(); }

if ( ! GetOptions (
		   "f|data_file=s"     => \$data_file,
		   "j|job_name=s"      => \$job_name,
		   "g|groups_list=s"   => \$groups_list,
		   "s|sig_if=s"        => \$sig_if,
		   "z|dist_pipe=s"     => \$dist_pipe,
		   "q|qiime_format=s"  => \$qiime_format,
		   "i|input_dir=s"     => \$input_dir,
		   "o|output_prefix=s"    => \$output_prefix,
		   "output_PCoA_dir=s" => \$output_PCoA_dir,
		   "print_dist=i"      => \$print_dist,
		   "output_DIST_dir"   => \$output_DIST_dir,
		   "m|dist_method=s"   => \$dist_method,
		   "a|tree=s"          => \$tree,
		   "headers=i"         => \$headers,
		   "x|perm_dir"        => \$perm_dir,
		   "t|perm_type=s"     => \$perm_type,
		   "p|num_perm=i"      => \$num_perm,
		   "c|num_cpus=i"      => \$num_cpus,
		   "cleanup!"          => \$cleanup,
		   "help!"             => \$help, 
		   "verbose!"          => \$verbose,
		   "debug!"            => \$debug
		  )
   ) { &usage(); }

# flip $create_perm_pcoas to 0 if cleanup option is selection
# this does not work right == hard coded to 1
# if ($cleanup){ $create_perm_pcoas = 0; }
#$create_perm_pcoas = 1;

# create name for the output directory
# if ($output_prefix eq "NA"){
#   $output_prefix = $current_dir."plot_pco_with_stats.".$data_file.".".$dist_pipe.".".$dist_method.".".$perm_type.".RESULTS/";
# }else{
#   $output_prefix = $current_dir.$output_prefix.".plot_pco_with_stats.".$data_file.".".$dist_pipe.".".$dist_method.".".$perm_type.".RESULTS/";
# }
if ($output_prefix eq "NA"){
  $output_prefix = $current_dir.$job_name.".RESULTS/";
}else{
  $output_prefix = $current_dir.$job_name.".".$output_prefix.".RESULTS/";
}

# create names for subdirectories of the output directory
$output_PCoA_dir =      $output_prefix."PCoAs/";
$output_DIST_dir =      $output_prefix."DISTs/";
$output_avg_DISTs_dir = $output_prefix."AVG_DISTs/";
$perm_dir =             $output_prefix."permutations/";

# name P value summary output file
my $output_p_value_summary = $output_prefix.$data_file.".".$dist_method.".".$perm_type.".P_VALUES_SUMMARY";

# create directories for the output files
unless (-d $output_prefix) { mkdir $output_prefix or die "can't mkdir $output_prefix";  } #### <---------- THIS IS WHAT HAS TO BE FIXED
unless (-d $perm_dir) { mkdir $perm_dir or die "can't mkdir $perm_dir"; }
unless (-d $output_PCoA_dir) { mkdir $output_PCoA_dir or die "can't mkdir $output_PCoA_dir"; }
unless (-d $output_DIST_dir) { mkdir $output_DIST_dir or die "can't mkdir $output_DIST_dir"; }
unless (-d $output_avg_DISTs_dir) { mkdir $output_avg_DISTs_dir or die "can't mkdir $output_avg_DISTs_dir";}

# create a log file and print all of the input parameters to it
my $log_file_name = $output_prefix."/".$data_file.".".$dist_method.".".$perm_type.".log";
open($log_file, ">", $log_file_name) or die "cannot open $log_file $log_file_name";
print $log_file "start:"."\t".$time_stamp."\n";
print $log_file "\n"."PARAMETERS USED:"."\n";
if ($data_file)       {print $log_file "     data_file:      "."\t".$data_file."\n";}
if ($job_name)        {print $log_file "     job_name:       "."\t".$job_name."\n";}
if ($groups_list)     {print $log_file "     groups_list:    "."\t".$groups_list."\n";}
if ($sig_if)          {print $log_file "     sig_if:         "."\t".$sig_if."\n";}
if ($dist_pipe)       {print $log_file "     dist_pipe:      "."\t".$dist_pipe."\n";}
if ($qiime_format)    {print $log_file "     qiime_format:   "."\t".$qiime_format."\n";}
if ($input_dir)       {print $log_file "     input_dir:      "."\t".$input_dir."\n";}
if ($output_prefix)   {print $log_file "     output_prefix:     "."\t".$output_prefix."\n";}
if ($output_PCoA_dir) {print $log_file "     output_PCoA_dir:"."\t".$output_PCoA_dir."\n";}
if ($print_dist)      {print $log_file "     print_dist:     "."\t".$print_dist."\n";}
if ($output_DIST_dir) {print $log_file "     output_DIST_dir:"."\t".$output_DIST_dir."\n";}
if ($dist_method)     {print $log_file "     dist_method:    "."\t".$dist_method."\n";}
if ($tree)            {print $log_file "     tree:           "."\t".$tree."\n";}
if ($headers)         {print $log_file "     headers:        "."\t".$headers."\n";}
if ($perm_dir)        {print $log_file "     perm_dir:       "."\t".$perm_dir."\n";}
if ($perm_type)       {print $log_file "     perm_type:      "."\t".$perm_type."\n";}
if ($num_perm)        {print $log_file "     num_perm:       "."\t".$num_perm."\n";}
if ($num_cpus)        {print $log_file "     num_cpus:       "."\t".$num_cpus."\n";}
if ($cleanup)         {print $log_file "     cleanup:        "."\t".$cleanup."\n";}
if ($help)            {print $log_file "     help:           "."\t".$help."\n";}
if ($verbose)         {print $log_file "     verbose:        "."\t".$verbose."\n";}
if ($debug)           {print $log_file "     debug:          "."\t".$debug."\n\n";}

##################################################
##################################################
###################### MAIN ######################
##################################################
##################################################

# exit if phylogentic analysis is selected without a valid tree
if ( $dist_method =~ m/frac/ ){ 
  if ($tree eq "NO DEFAULT") {
    
    my $error_string = "
          You selected a phylogenetic analysis (like unifrac or weighted_unifrac),
     but you did not specify a valid -tree argument; a value was not provided, 
     the specified tree file (*.tre) does not exist, or is an empty file.

          The tree you specified was:

          $tree \n\n";
    
    print $log_file $error_string;
    print STDOUT $error_string;
    exit 1;
  }
}

# exit if qiime pipe is selected with R_table
if( $dist_pipe eq "qiime_pipe" ){
  if( $qiime_format eq "biom" ){
    print $log_file "dist_pipe: ( ".$dist_pipe." ) is ok with qiime_format ( ".$qiime_format." ), proceeding"."\n";
  }elsif ( $qiime_format eq "qiime_table" ){
    print $log_file "dist_pipe: ( ".$dist_pipe." ) is ok with qiime_format ( ".$qiime_format." ), proceeding"."\n";
  }else{
    print $log_file "dist_pipe: ( ".$dist_pipe." ) is not compatible with qiime_format ( ".$qiime_format." )"."\n".
      "you must choose biom or qiime_table as a qiime_format with the qiime_pip"."\n";
    print STDOUT "dist_pipe: ( ".$dist_pipe." ) is not compatible with qiime_format ( ".$qiime_format." )"."\n".
      "you must choose biom or qiime_table as a qiime_format with the qiime_pip"."\n";
    exit 1;
  }
}

# function to log running status
my $running_text = &running();
print $log_file $running_text;

##### Make sure that the input files don't have nutty line terminators (creep in when you use excel to modify the files)
&correct_line_terminators($input_dir, $data_file);
&correct_line_terminators($input_dir, $groups_list);


##### Make sure that the groups_list only contains headers that exist in the data file -- kill the program as soon as they don't
$check_status = check_groups($input_dir, $data_file, $groups_list);
unless ($check_status eq "All groups members match a header from the data file"){
  print $log_file $check_status."JOB KILLED";
  exit 1;
}else{
  print $log_file $check_status.", proceeding"."\n\n";
}


##########################################
########## PROCESS ORIGNAL DATA ##########
##########################################

# correct selected pipe for unifrac and OTU dists if needed
if ( $dist_method =~ m/frac/ ){ 
  $dist_pipe = "qiime_pipe";
  print $log_file "warning: dist_pipe changed to ".$dist_pipe." to handle dist_method ".$dist_method."\n";    
}elsif ( $dist_method =~ m/OTU/ ) { 
  $dist_pipe = "OTU_pipe"; 
  print $log_file "warning: dist_pipe changed to ".$dist_pipe." to handle dist_method ".$dist_method."\n";
}else{
  print $log_file "ok: selected dist_pipe ".$dist_pipe." can handle dist_method ".$dist_method."\n";
}



# process original (non permuted) data using qiime to calculate all distances/ dissimilarities
if ( $dist_pipe eq "qiime_pipe" ){
  process_original_qiime_data($dist_pipe, $data_file, $qiime_format, $dist_method, $tree, $input_dir, $output_prefix, $log_file, $DIR)
}elsif ( $dist_pipe eq "OTU_pipe" ){
    process_original_OTU_data($dist_pipe, $data_file, $dist_method, $input_dir, $output_prefix, $log_file, $DIR)
}elsif ( $dist_pipe eq "MG-RAST_pipe" ){
        process_original_data($dist_pipe, $data_file, $dist_method, $input_dir, $output_prefix, $log_file, $DIR)
}else{
  print STDOUT "\n\n"."The selected dist_pipe (".$dist_pipe.") is not recognized - please check and try again"."\n";
  print $log_file "\n\n"."The selected dist_pipe (".$dist_pipe.") is not recognized - please check and try again"."\n";
  exit 1;
}



# generate and process permuted data
if ( $dist_pipe eq "qiime_pipe" ){
  process_permuted_qiime_data($dist_pipe, $data_file, $output_prefix, $perm_list, $num_cpus, $num_perm, $perm_dir, $output_PCoA_dir, $create_perm_pcoas, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $tree, $qiime_format, $headers, $log_file, $DIR)
}elsif ( $dist_pipe eq "OTU_pipe" ){
  process_permuted_OTU_data($dist_pipe, $data_file, $output_prefix, $perm_list, $num_cpus, $num_perm, $perm_dir, $output_PCoA_dir, $create_perm_pcoas, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $headers, $log_file, $DIR)
}elsif ( $dist_pipe eq "MG-RAST_pipe" ) {
  process_permuted_data($dist_pipe, $data_file, $output_prefix, $perm_list, $num_cpus, $num_perm, $perm_dir, $output_PCoA_dir, $create_perm_pcoas, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $tree, $headers, $log_file, $DIR)
}else{
  print STDOUT "\n\n"."The selected dist_pipe (".$dist_pipe.") is not recognized - please check and try again"."\n";
  print $log_file "\n\n"."The selected dist_pipe (".$dist_pipe.") is not recognized - please check and try again"."\n";
  exit 1;
}


                                                                                                                        
# perform cleanup if specified
if ($cleanup) {
  print $log_file "\n"."Performing cleanup"."\n\n";
  &cleanup_sub();
}



# log running time
my $end = time;
my $min = int(($end - $start) / 60);
my $sec = ($end - $start) % 60;
print STDOUT "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print STDOUT "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";
print $log_file "\n\n"."all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print $log_file "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";


##################################################
##################################################
###################### SUBS ######################
##################################################
##################################################



# removed permutation files     
sub cleanup_sub { 
  my $cleanup_string = "rm $output_prefix*list*; rm -R $output_PCoA_dir; rm -R $output_DIST_dir; rm -R $output_avg_DISTs_dir; rm -R $perm_dir"; 
  print $log_file "\n"."executing:"."\n".$cleanup_string."\n";
  system($cleanup_string)==0 or die "died on cleanup";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
}



# usage / help
sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $time_stamp
script:               $0

DESCRIPTION:
This script performs pco analysis with group distances on an original data file, 
and a specified number of permutations of the original data to derive p values.
Please do not use quotes or special characters (e.g. \ ) for any specified parameters.
   
USAGE:
    -f|--data_file        (string)  !!! NO DEFAULT !!!

    -j|--job_name         (string)  default= $job_name
                                    job name (taken from commands list if run by AMETHST.pl) - specifies a pattern
                                    that is added as a prefix to the output directory
                                    original data file (in R compatible tab delimited format)

    -g|--groups_list      (string)  default = $groups_list
                                    file that contains groups list
                                    group per line, each sample in a group (line) is comma separated
                                    sample names should be same as in the data_file header

    -s|--sig_if           (string)  default = $sig_if        
                                    lt or gt - determines if permutation distances less or greater than 
                                    original are deemed significant
                                    The default \"lt\" is appropriate for determination of significance
                                    within a group -- distances are significant if they are less than
                                    that observed in the real data. Permutations would be expected to 
                                    exhibit within group distances larger than the original.
                                    We expect the opposite behvaior for between group distances; \"gt\" is 
                                    appropriate for determination of significance between groups.
                                    Permutations would be expected to exhibit between group distances
                                    smaller than those observed in the original data.

    -i|--input_dir        (string)  default = $current_dir
                                    path that containts the data file

    -o|--output_prefix    (string)  default = $output_prefix
                                    prefix appended to the output directory name.

    -p|--num_perm         (integer) default = $num_perm 
                                    number of permutations to perform

    -t|--perm_type        (string)  default = $perm_type 
                                    The type of permutation to be performed
                                         --> choose from the following three methods <--
                                              sample_rand   - randomize fields in sample/column
                                              dataset_rand  - randomize fields across dataset
                                              complete_rand - randomize every individual count across dataset
                                              rowwise_rand  - randomize fields in taxon/row 
                                              sampleid_rand - randomize sample/column labels only

    -m|--dist_method      (string)  default = $dist_method
                                    --> can slect from the following distances/dissimilarities <-- 
                                     (*)   bray-curtis | maximum  | canberra    | binary   | minkowski  | 
                                           euclidean   | jacccard | mahalanobis | sorensen | difference |
                                           manhattan
                                     (**)     OTU      |   w_OTU                                     
                                     (***)    ...    
                                    --> in addition, 
                                        *   MG-RAST_pipe supports listed metrics (R pacakges \"stats\" and \"ecodist\")
                                        **  OTU_pipe supports only the OTU and weighted_OTU (w_OTU) metrics
                                        *** all qiime metrics supported by qiime_pipe 
                                        (on a machine with qiime installed, see them with \"beta_diversity.py -s\")

    -z|--dist_pipe        (string)  default = $dist_pipe
                                    analysis pipe to use - in many (but not all) cases, the dist_method
                                    determines the dist_pipe (e.g. unifrac distance requires the qiime_pipe)
                                         --> choose from the following 3 pipes <--
                                              MG-RAST_pipe - distances calculated with R (ecodist and base) 
                                              qiime_pipe   - distances calculated with qiime
                                              OTU_pipe     - distances calculated with custom R scripts

    -q|qiime_format       (string)  default = $qiime_format 
                                    input qiime format (only used if dist_pipe = qiime_pipe)
                                         --> choose from the following 2 formats <--    
                                              biom        - biom file format (see http://www.biom-format.org)
                                              qiime_table - original qiime table format (tab delimited table)

    -a|tree               (string)  !!! NO DEFAULT !!! (optional parameter)
                                    path/file for *.tre file
                                    examples: /home/ubuntu/software/gg_otus-4feb2011-release/trees/gg_97_otus_4feb2011.tre
                                              /home/qiime/qiime_software/gg_otus-12_10-release/trees/97_otus.tree
                                    a *.tre file - only used with phylogenitically aware metrics like unifrac|weighted_unifrac

    -x|--perm_dir         (string)  default = $perm_dir
                                    directory to store permutations

    -c|--num_cpus         (integer) default = $num_cpus
                                    number of cpus to use (xargs)
    -----------------------------------------------------------------------------------------------
    --cleanup          (flag)       delete all of the permutation temp files
    --help             (flag)       see the help/usage
    --verbose          (flag)       run in verbose mode
    --debug            (flag)       run in debug mode

);
  exit 1;
}



# script to report running status to STDOUT and to the log
sub running {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  my $running_text = qq(
RUNNING
------------------------------------------
job:                  $job_name
script:               $0
time stamp:           $time_stamp
------------------------------------------
);
  
  print STDOUT $running_text;

  return $running_text;

}



# create a list of pattern matching files in a directory
sub list_dir {
  
  my($dir_name, $list_pattern, $dir_list) = @_;
  
  open(DIR_LIST, ">", $dir_list) or die "\n\n"."can't open DIR_LIST $dir_list"."\n\n";
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  print DIR_LIST join("\n", @dir_files_list); print DIR_LIST "\n";
  closedir DIR or die "can't closedir DIR $dir_name";

  return @dir_files_list;
  
}



# correct line terminators
sub correct_line_terminators {
  
  my($input_dir, $file) = @_;
  
  my $temp_file = $file.".tmp";
  
  open(FILE, "<", $input_dir."/".$file) or die "Couldn't open FILE $file"."\n";
  open(TEMP_FILE, ">", $input_dir."/".$temp_file) or die "Couldn't open TEMP_FILE $temp_file"."\n";
  
  while (my $line = <FILE>){          
    $line =~ s/\r\n|\n\r|\n|\r/\n/g;  #get rid of the line ends that are there #replace them with \n
    print TEMP_FILE $line; 
  }
  close FILE or die "can't close FILE $file";
  close TEMP_FILE or die "can't close TEMP_FILE $temp_file";
  
  unlink $input_dir."/".$file or die "\n"."Couldn't delete FILE $file"."\n";
  rename $input_dir."/".$temp_file, $input_dir."/".$file or die "\n"."Couldn't rename TEMP_FILE $temp_file to FILE $file"."\n";
  
}



# Process the original (non permuted) data, MG-RAST annotations
sub process_original_data {

  my ($dist_pipe, $data_file, $dist_method, $input_dir, $output_prefix, $log_file, $DIR) = @_;

  # process the original data_file to produce PCoA and DIST files
  my $original_data_dists_string = "$DIR/plot_pco_shell.sh $data_file $input_dir $output_prefix 1 $output_prefix $dist_method $headers";   		  
  print $log_file "\n"."executing:"."\n".$original_data_dists_string."\n";
  system($original_data_dists_string)==0 or die "died running command"."\n".$original_data_dists_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
  # Process original data_file.DIST to produce original_file.DIST.AVG_DIST
  my $original_data_avg_dists_string = "$DIR/avg_distances.sh $data_file.$dist_method.DIST $output_prefix $groups_list $data_file.$dist_method.DIST $output_prefix";
  print $log_file "\n"."executing:"."\n".$original_data_avg_dists_string."\n";
  system($original_data_avg_dists_string)==0 or die "died running command"."\n".$original_data_avg_dists_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
 
}

     
# Process the original (non permuted) data, Qiime annotations
sub process_original_qiime_data {

  my ($dist_pipe, $data_file, $qiime_format, $dist_method, $tree, $input_dir, $output_prefix, $log_file, $DIR) = @_;
   
  # create name for biom formatted file
  my $biom_file = $data_file.".biom";
  my $R_table_file = $data_file.".R_table";
  my $qiime_table = $data_file.".qiime_table";
  
  # file conversions -- copy biom to biom, convert qiime_table to biom, or quit
  if ( $qiime_format eq "qiime_table" ){ # handle qiime_table format as input
    print $log_file "dist_pipe is (".$dist_pipe.") and qiime_format is (".$qiime_format.")"."\n".
      "if this is not correct - processing will fail unexpected results"."\n".
      "converting $qiime_format to biom format for compatibility qiime beta_diversity.py"."\n"; 
    my $qiime_table_2_biom_string = "convert_biom.py -i $input_dir$data_file -o $output_prefix$biom_file --biom_table_type=\"otu table\""; 
    print $log_file "\n"."executing:"."\n".$qiime_table_2_biom_string."\n";
    system($qiime_table_2_biom_string)==0 or die "died running command"."\n".$qiime_table_2_biom_string."\n";
    #system($qiime_table_2_biom_string); #or die "died running command"."\n".$qiime_table_2_biom_string."\n";
    print $log_file "\n"."Creating R_table from qiime_table";
    my $qiime_table_2_R_table_string = "$DIR/qiime_2_R.pl -i $input_dir$data_file -c 3 -o $output_prefix$data_file";
    print $log_file "\n"."executing:"."\n".$qiime_table_2_R_table_string."\n";
    system($qiime_table_2_R_table_string)==0 or die "died running command"."\n".$qiime_table_2_R_table_string."\n";
    print $log_file "\n"."Copying qiime_table from qiime_table";
    my $copy_qiime_table_string = "cp $input_dir$data_file $output_prefix$qiime_table";
    print $log_file "\n"."executing:"."\n".$copy_qiime_table_string."\n";
    system($copy_qiime_table_string)==0 or die "died running command"."\n".$copy_qiime_table_string."\n";
    print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 
  
  }elsif( $qiime_format eq "biom" ){ # handle biom format as input
    print $log_file "dist_pipe is (".$dist_pipe.") and qiime_format is (".$qiime_format.")".      
      "OK"."\n".
	"if this is not correct - processing will fail unexpected results"."\n";
    print $log_file "If your biom data are in another format (biom or r_table, indiciate with the qiime_format option )";
    my $copy_biom_string = "cp $input_dir$data_file $output_prefix$biom_file";
    print $log_file "\n"."executing:"."\n".$copy_biom_string."\n";
    system($copy_biom_string)==0 or die "died running command"."\n".."\n";
    print $log_file "\n"."Creating qiime_table from biom file";
    my $biom_2_qiime_table_string = "convert_biom.py -b -i $output_prefix$biom_file -o $output_prefix$qiime_table --header_key taxonomy";
    print $log_file "\n"."executing:"."\n".$biom_2_qiime_table_string."\n";
    system($biom_2_qiime_table_string)==0 or die "died running command"."\n".$biom_2_qiime_table_string."\n";
    #system($biom_2_qiime_table_string); # or die "died running command"."\n".$biom_2_qiime_table_string."\n";
    print $log_file  "\n"."Creating R_table from qiime_table";
    my $qiime_table_2_R_table_string = "$DIR/qiime_2_R.pl -i $input_dir$data_file -c 3 -o $output_prefix$data_file";
    print $log_file "\n"."executing:"."\n".$qiime_table_2_R_table_string."\n";
    system($qiime_table_2_R_table_string)==0 or die "died running command"."\n".$qiime_table_2_R_table_string."\n";
    print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
  }else{ # handle R_table format as input (fail)
    print $log_file "dist_pipe is (".$dist_pipe.") and qiime_format is (".$qiime_format.")"."\n"."These are not compatible"."\n";
    print STDOUT "dist_pipe is (".$dist_pipe.") and qiime_format is (".$qiime_format.")"."\n"."These are not compatible"."\n";
    print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
    exit 1;
  }
  
  ##### produce a distance matrix (*.DIST) using qiime - *.tre needed for phylogenetically aware metrics (i.e. unifracs)
  # calculate unifrac or weighted-unifrac distance
  if ( $dist_method =~ m/frac/) { 
    
    my $calculate_frac_distance_string = "beta_diversity.py -i $output_prefix$biom_file -o $output_prefix -m $dist_method -t $tree"."\n\n";
    print $log_file "\n"."executing:"."\n".$calculate_frac_distance_string."\n";
    system($calculate_frac_distance_string)==0 or die "died running command"."\n".$calculate_frac_distance_string."\n";
    print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
  }else{ # calculate non "frac" distances

    my $calculate_non_frac_distance_string = "beta_diversity.py -i $output_prefix$biom_file -o $output_prefix -m $dist_method";
    print $log_file "\n"."executing:"."\n".$calculate_non_frac_distance_string."\n";
    system($calculate_non_frac_distance_string)==0 or die "died running command"."\n".$calculate_non_frac_distance_string."\n";
    print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 

  }
  
  # rename the output dist file
  my $qimme_dist_filename = $output_prefix.$dist_method."_".$data_file.".txt";
  my $dist_filename = $data_file.".".$dist_method.".DIST";
  my $rename_dist_string = "mv $qimme_dist_filename $output_prefix$dist_filename";
  print $log_file "\n"."executing:"."\n".$rename_dist_string."\n";
  system($rename_dist_string)==0 or die "died running command"."\n".$rename_dist_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # generate PCoA
  my $pcoa_file = $data_file.".".$dist_method.".PCoA";
  my $perform_pcoa_string = "$DIR/plot_qiime_pco_shell.sh $output_prefix$dist_filename $output_prefix$pcoa_file";
  print $log_file "\n"."executing:"."\n".$perform_pcoa_string."\n";
  system($perform_pcoa_string)==0 or die "died running command"."\n".$perform_pcoa_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 

  # create average_dist file
  my $avg_dist_filename = $data_file.".".$dist_method.".DIST";
  my $create_avg_dist_string = "$DIR/avg_distances.sh $dist_filename $output_prefix $groups_list $avg_dist_filename $output_prefix";
  print $log_file "\n"."executing:"."\n".$create_avg_dist_string."\n";
  system($create_avg_dist_string)==0 or die "died running command"."\n".$create_avg_dist_string."\n";
  print $log_file "Produce *.AVG_DIST file from the original data *.DIST file"."\n"."DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

}

# Process the original (non permuted) data, with OTU distances
sub process_original_OTU_data {

  my ($dist_pipe, $data_file, $dist_method, $input_dir, $output_prefix, $log_file, $DIR) = @_;

  if ($debug){ print STDERR "HELLO.OTU.1"."\n"; }
  # process the original data_file to produce PCoA and DIST files
  print $log_file "process original data file (".$data_file.") > *.PCoA & *.DIST ... "."\n";
  my $process_original_OTU_string = "$DIR/OTU_similarities_shell.sh $data_file $input_dir $output_prefix 1 $output_prefix $dist_method $headers";
  print $log_file "\n"."executing:"."\n".$process_original_OTU_string."\n";
  system($process_original_OTU_string)==0 or die "died running command"."\n".$process_original_OTU_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  if ($debug){ print STDERR "HELLO.OTU.2"."\n"; }
  # process original data_file.DIST to produce original_file.DIST.AVG_DIST
  print $log_file "process original data *.DIST file (".$data_file.".".$dist_method.".DIST) > *.AVG_DIST ... "."\n";
  my $process_OTU_avg_distances_string = "$DIR/avg_distances.sh $data_file.$dist_method.DIST $output_prefix $groups_list $data_file.$dist_method.DIST $output_prefix";
  print $log_file "\n"."executing:"."\n".$process_OTU_avg_distances_string."\n";
  system($process_OTU_avg_distances_string)==0 or die "died running command"."\n".$process_OTU_avg_distances_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

}



sub process_permuted_data {

  my($dist_pipe, $data_file, $output_prefix, $perm_list, $num_cpus, $num_perm, $perm_dir, $output_PCoA_dir, $create_perm_pcoas, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $tree, $headers, $log_file, $DIR) = @_;

  # use R script sample_matrix.r to generate permutations of the original data
  print $log_file "generate (".$num_perm.") permutations ... "."\n";

  #create R script to generate permutations
  my $R_permutation_script_string = (
				     "# script generated by plot_pco_with_stats.pl to run sample_matrix.r"."\n".
				     "source(\"$DIR/sample_matrix.r\")"."\n".
				     "sample_matrix(file_name = \"$data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 0)"
				    );
  my $R_rand_script = "$data_file.R_sample_script.".$time_stamp.".r";
  print $log_file "\n".$R_rand_script." contains this:"."\n".$R_permutation_script_string."\n\n"; 
  open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";
  print R_SCRIPT $R_permutation_script_string;

  # run the R script to generate the permutations
  my $generate_permutations_string = "R --vanilla --slave < $R_rand_script";
  print $log_file "\n"."executing:"."\n".$generate_permutations_string."\n";
  system($generate_permutations_string)==0 or die "died running command"."\n".$generate_permutations_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # Delete the R script
  my $delete_permutation_script_string = "rm $R_rand_script";
  print $log_file "\n"."executing:"."\n".$delete_permutation_script_string."\n";
  system($delete_permutation_script_string)==0 or die "died running command"."\n".$delete_permutation_script_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
  # create list of the permutation files
  print $log_file "creating list of permutated data files:"."\n".$output_prefix.$perm_list."\n";
  &list_dir($perm_dir, "permutation",  $output_prefix.$perm_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # perform PCoA on all of the permutations - outputs placed in directories created for the PCoA and DIST files
  #if ($create_perm_pcoas){
  my $pcoa_permutations_script_string =  "cat $output_prefix$perm_list | xargs -n1 -P$num_cpus -I{} $DIR/plot_pco_shell.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers";
  print $log_file "\n"."executing:"."\n".$pcoa_permutations_script_string."\n";
  system( $pcoa_permutations_script_string )==0 or die "died running command"."\n".$pcoa_permutations_script_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  #}else{
  #  print $log_file "\n"."PCoAs not generated for permutations (not generated when the cleanup option is selected)"."\n\n"
  #}

  # Create list of all permutation *.DIST files
  print $log_file "creating list of *.DIST files produced from permutated data ... "."\n".$output_prefix.$dist_list."\n"; 
  &list_dir($output_DIST_dir, ".DIST",  $output_prefix.$dist_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # Create *.DIST.AVG_DIST from *.DIST
  my $avg_dist_string = "cat $output_prefix$dist_list | xargs -n1 -P$num_cpus -I{} $DIR/avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir";
  print $log_file "\n"."executing:"."\n".$avg_dist_string."\n";
  system ( $avg_dist_string )==0 or die "died running command"."\n".$avg_dist_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
 
  # Create a list of all the *.AVG_DIST files
  print $log_file "creating list of *.AVG_DIST files:"."\n".$output_prefix.$avg_dists_list."\n"; 
  &list_dir($output_avg_DISTs_dir, "AVG_DIST", $output_prefix.$avg_dists_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  my $output_p_value_summary = $output_prefix.$data_file.".".$dist_method.".P_VALUES_SUMMARY";
  my $og_avg_dist_filename = $output_prefix.$data_file.".".$dist_method."."."DIST.AVG_DIST";
  my $produce_ps_string = "$DIR/avg_dist_summary.pl -og_avg_dist_file $og_avg_dist_filename -sig_if $sig_if -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_prefix$avg_dists_list -output_file $output_p_value_summary";
  print $log_file "\n"."executing:"."\n".$produce_ps_string."\n";
  system( $produce_ps_string )==0 or die "died running command"."\n".$produce_ps_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

}



sub process_permuted_qiime_data { # starts with biom format

  my($dist_pipe, $data_file, $output_prefix, $perm_list, $num_cpus, $num_perm, $perm_dir, $output_PCoA_dir, $create_perm_pcoas, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $tree, $qiime_format, $headers, $log_file, $DIR) = @_;

  # Create a version of the QIIME table in R friendly format
  my $qiime_table_2_R_table_string = "$DIR/qiime_2_R.pl -i $input_dir$data_file -o $output_prefix$data_file -c 3";
  print $log_file "\n"."executing:"."\n".$qiime_table_2_R_table_string."\n";
  system( $qiime_table_2_R_table_string )==0 or die "died running command"."\n".$qiime_table_2_R_table_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # use R script sample_matrix.r to generate permutations of the original data
  print $log_file "generate (".$num_perm.") permutations ... "."\n";

  #create R script to generate the R_table permutations
  my $R_permutation_script_string = (
				     "# script generated by plot_qiime_pco_with_stats.pl to run sample_matrix.r"."\n".
				     "source(\"$DIR/sample_matrix.r\")"."\n".
				     "sample_matrix(file_name = \"$data_file.qiime_ID_and_tax_string.R_table\", file_dir = \"$output_prefix\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 1)"
				    );
  my $R_rand_script = "$data_file.R_sample_script.".$time_stamp.".r";
  print $log_file "\n".$R_rand_script." contains this:"."\n".$R_permutation_script_string."\n\n"; 
  open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";
  print R_SCRIPT $R_permutation_script_string;

  # run the R script to generate the permuted R_table(s)
  my $generate_permutations_string = "R --vanilla --slave < $R_rand_script";
  print $log_file "\n"."executing:"."\n".$generate_permutations_string."\n";
  system($generate_permutations_string)==0 or die "died running command"."\n".$generate_permutations_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # Delete the R script that created the permutations
  my $delete_permutation_script_string = "rm $R_rand_script";
  print $log_file "\n"."executing:"."\n".$delete_permutation_script_string."\n";
  system($delete_permutation_script_string)==0 or die "died running command"."\n".$delete_permutation_script_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # create list of the permuated R_tables
  my $R_table_perm_list = $perm_list.".R_table";
  my @R_permutation_list = &list_dir($perm_dir, "R_table",  $output_prefix.$R_table_perm_list);
  
  # generate qiime formatted versions of the permuted data tables # could use xargs here too ?
  foreach my $R_permutation (@R_permutation_list){
    if ( $debug ){ print "HELLO - R_PERM:     ".$R_permutation."\n"; }
    my $R_table_2_qiime_table_string = "$DIR/qiime_2_R.pl -i $perm_dir$R_permutation -c 5";
    print $log_file "\n"."executing:"."\n".$R_table_2_qiime_table_string."\n";
    system($R_table_2_qiime_table_string)==0 or die "died running command"."\n".$R_table_2_qiime_table_string."\n";
    #if($cleanup){ # delete R_tables (keep qiime_tables)
    #my $cleanup_string = "rm $perm_dir$R_permutation";
    #print $log_file "\n"."executing:".$cleanup_string."\n";
    #system($cleanup_string);
    #}
  }
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # generate biom format file for each qiime_formattted permutation table # could use xargs here too ?
  # generate list of the qiime_table files
  my $qiime_table_perm_list = $perm_list.".qiime_table";
  my @Qiime_permutation_list = &list_dir($perm_dir, "Qiime_table\$",  $output_prefix.$qiime_table_perm_list);
  # create biom file for each qiime_table file
  foreach my $Qiime_permutation (@Qiime_permutation_list){
    if ( $debug ){ print "HELLO - QIIME_PERM: ".$Qiime_permutation."\n"; }
    my $biom_permutation = $Qiime_permutation.".biom";
    my $qiime_table_2_biom_string = "convert_biom.py -i $perm_dir$Qiime_permutation -o $perm_dir$biom_permutation --biom_table_type=\"otu table\"";  
    print $log_file "\n"."executing:"."\n".$qiime_table_2_biom_string."\n";
    system($qiime_table_2_biom_string)==0 or die "died running command"."\n".$qiime_table_2_biom_string."\n";
    #system($qiime_table_2_biom_string); # or die "died running command"."\n".$qiime_table_2_biom_string."\n";
    #if($cleanup){ # delete qiime_tables -- leaving the permuted biom files ...
    #my $cleanup_string = "rm $perm_dir$Qiime_permutation";
    #print $log_file "\n"."executing:"."\n".$cleanup_string."\n";
    #system($cleanup_string);
    #}
  }
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
 
  # produce *.DIST files for each permutation - using qiime beta_diversity.py
  # generate list of the biom files
  my $biom_file_list = $perm_list.".biom";
  if ($debug){print STDOUT "Hello"; print $log_file "\n\n"."Hello"."\n\n"."biom_list_file: ".$output_prefix.$biom_file_list."\n\n"; }
  my @biom_permutation_list = &list_dir($perm_dir, ".biom\$",  $output_prefix.$biom_file_list);  
  if ($debug){print STDERR "HELLO.1"."\n";}
  # generate Qiime based distances
  if ( $dist_method =~ m/frac/ ) { # add the tree argument to beta_diversity.py for unifrac (phylogenetically aware) analyses
    my $calc_frac_dists_string = "cat $output_prefix$biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method -t $tree";
    print $log_file "\n"."executing:"."\n".$calc_frac_dists_string."\n";
    system( $calc_frac_dists_string )==0 or die "died running command"."\n".$calc_frac_dists_string."\n";
    "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  }else{
    my $calc_non_frac_dists_string = "cat $output_prefix$biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method";
    print $log_file "\n"."executing:"."\n".$calc_non_frac_dists_string."\n";
    system( $calc_non_frac_dists_string )==0 or die "died running command"."\n".$calc_non_frac_dists_string."\n";
    print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  }

  # rename the output dist files
  # change dist file names -- change extensions from *.txt to *.DIST
  print $log_file "\n"."Renaming qiime permutation dists - changing extension from *.txt to *.DIST";
  my $qiime_dist_file_list = $output_DIST_dir."qiime_dist_file_list";
  my @qiime_dist_permutation_list = &list_dir($output_DIST_dir, ".txt", $qiime_dist_file_list);
  foreach my $qiime_dist_name (@qiime_dist_permutation_list){
    chomp $qiime_dist_name;
    if($debug){print "\n"."qiime_dist_name   :".$qiime_dist_name."\n"};

    #my @qiime_dist_array;
    my @qiime_dist_array = split(/\./, $qiime_dist_name);

    if($debug){print "scalar: ".scalar(@qiime_dist_array)."\n";}
    pop(@qiime_dist_array);
    if($debug){print "scalar: ".scalar(@qiime_dist_array)."\n";}
    push(@qiime_dist_array, "DIST");
    if($debug){print "scalar: ".scalar(@qiime_dist_array)."\n";}
    my $qiime_dist_renamed;
    $qiime_dist_renamed = join(".", @qiime_dist_array);
    if($debug){print "qiime_dist_renamed:".$qiime_dist_renamed."\n"};
    my $rename_string = "mv $output_DIST_dir$qiime_dist_name $output_DIST_dir$qiime_dist_renamed"; 
    print $log_file "\n"."executing"."\n".$rename_string."\n";
    if($debug){print "\n".$rename_string."\n"; }
    system($rename_string)==0 or die "died running command"."\n".$rename_string."\n";
  }
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # create list of renamed *.DIST files
  my $dist_file_list = $output_DIST_dir."dist_file_list";
  my @dist_permutation_list = &list_dir($output_DIST_dir, ".DIST", $dist_file_list);

  if ($debug){print STDERR "HELLO.2"."\n";}
  
  # produce *.AVG_DIST file for each *.DIST file
  open(DIST_FILE_LIST, ">", $dist_file_list) or die "can't open DIST_FILE_LIST $dist_file_list";
  print DIST_FILE_LIST join("\n", @dist_permutation_list);
  close(DIST_FILE_LIST) or die "can't close DIST_FILE_LIST $dist_file_list";
  my $avg_dist_string = "cat $dist_file_list | xargs -n1 -P $num_cpus -I{} $DIR/avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir";
  print $log_file "\n"."executing:"."\n".$avg_dist_string."\n";
  system ( $avg_dist_string )==0 or die "died running command"."\n".$avg_dist_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  if ($debug){print STDERR "HELLO.3"."\n";}

  # create list of the permutation files (they are biom format at this point)
  print $log_file "creating list of permutated data files:"."\n".$output_prefix.$perm_list."\n";
  &list_dir($perm_dir, "permutation",  $output_prefix.$perm_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  if ($debug){print STDERR "HELLO.4"."\n";}

  # use R to produce PCoAs for each permutation
  # This code needs work -- is not operable as is
  # if($create_perm_pcoas){
  #   my $pcoa_permutations_script_string =  "cat $dist_file_list | xargs -n1 -P$num_cpus -I{} $DIR/plot_qiime_pco_shell.sh $output_DIST_dir {} $output_PCoA_dir {}.PCoA";
  #   print $log_file "\n"."executing:"."\n".$pcoa_permutations_script_string."\n";
  #   system( $pcoa_permutations_script_string );
  #   print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  # }else{
  #   print $log_file "\n"."PCoAs not generated for permutations (not generated when the cleanup option is selected)"."\n\n";
  # }

  print $log_file "\n"."PCoAs not generated for permutations (revisions to the exisiting code are neccessary to add this feature)"."\n\n";

  if ($debug){print STDERR "HELLO.5"."\n";}

  # Create a list of all the *.AVG_DIST files
  print $log_file "creating list of *.AVG_DIST files ... "."\n"; 
  &list_dir($output_avg_DISTs_dir, "AVG_DIST", $output_prefix.$avg_dists_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  if ($debug){print STDERR "HELLO.6"."\n";}

  # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  my $output_p_value_summary = $output_prefix.$data_file.".".$dist_method.".P_VALUES_SUMMARY";
  my $og_avg_dist_filename = $output_prefix.$data_file.".".$dist_method."."."DIST.AVG_DIST";
  my $produce_ps_string = "$DIR/avg_dist_summary.pl -og_avg_dist_file $og_avg_dist_filename -sig_if $sig_if -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_prefix$avg_dists_list -output_file $output_p_value_summary";
  print $log_file "\n"."executing:"."\n".$produce_ps_string."\n";
  system( $produce_ps_string )==0 or die "died running command"."\n".$produce_ps_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  if ($debug){print STDERR "HELLO.7"."\n";}

}



sub process_permuted_OTU_data {

  my($dist_pipe, $data_file, $output_prefix, $perm_list, $num_cpus, $num_perm, $perm_dir, $output_PCoA_dir, $create_perm_pcoas, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $headers, $log_file, $DIR) = @_;
  
  print $log_file "generate (".$num_perm.") permutations ... "."\n";

  #create R script to generate the R_table permutations
  my $R_permutation_script_string = ( "# script generated by plot_pco_with_stats.pl to run sample_matrix.r"."\n".
				      "source(\"$DIR/sample_matrix.r\")"."\n".
				      "sample_matrix(file_name = \"$data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 0)"
				    );
  my $R_rand_script = "$data_file.R_sample_script.".$time_stamp.".r";
  print $log_file "\n".$R_rand_script." contains this:"."\n".$R_permutation_script_string."\n\n"; 
  open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";
  print R_SCRIPT $R_permutation_script_string;

  # run the R script to generate the permutations
  my $generate_permutations_string = "R --vanilla --slave < $R_rand_script";
  print $log_file "\n"."executing:"."\n".$generate_permutations_string."\n";
  system($generate_permutations_string)==0 or die "died running command"."\n".$generate_permutations_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # Delete the R script
  my $delete_permutation_script_string = "rm $R_rand_script";
  print $log_file "\n"."executing:"."\n".$delete_permutation_script_string."\n";
  system($delete_permutation_script_string)==0 or die "died running command"."\n".$delete_permutation_script_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
  # create list of the permutation files
  print $log_file "creating list of permutated data files:"."\n".$output_prefix.$perm_list."\n";
  &list_dir($perm_dir, "permutation",  $output_prefix.$perm_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
 
  # perform PCoA on all of the permutations - outputs placed in directories created for the PCoA and DIST files
  #if($create_perm_pcoas){
  my $pcoa_permutations_script_string = "cat $output_prefix$perm_list | xargs -n1 -P$num_cpus -I{} $DIR/OTU_similarities_shell.7-31-12.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers";
  print $log_file "\n"."executing:"."\n".$pcoa_permutations_script_string;
  system( $pcoa_permutations_script_string )==0 or die "died running command"."\n".$pcoa_permutations_script_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
  #}else{
  #  print $log_file "\n"."PCoAs not generated for permutations (not generated when the cleanup option is selected)"."\n\n"
  #}

  # Create list of all permutation *.DIST files
  print $log_file "creating list of *.DIST files produced from permutated data ... "."\n".$output_prefix.$dist_list."\n";
  &list_dir($output_DIST_dir, ".DIST", $output_prefix.$dist_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Create *.DIST.AVG_DIST from *.DIST
  my $avg_dist_string = "cat $output_prefix$dist_list | xargs -n1 -P$num_cpus -I{} $DIR/avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir";
  print $log_file "\n"."executing:"."\n".$avg_dist_string."\n";
  system ( $avg_dist_string )==0 or die "died running command"."\n".$avg_dist_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # Create a list of all the *.AVG_DIST files
  print $log_file "creating list of *.AVG_DIST files:"."\n".$output_prefix.$avg_dists_list."\n"; 
  &list_dir($output_avg_DISTs_dir, "AVG_DIST", $output_prefix.$avg_dists_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  my $output_p_value_summary = $output_prefix.$data_file.".".$dist_method.".P_VALUES_SUMMARY";
  my $og_avg_dist_filename = $output_prefix.$data_file.".".$dist_method."."."DIST.AVG_DIST";
  my $produce_ps_string = "$DIR/avg_dist_summary.pl -og_avg_dist_file $og_avg_dist_filename -sig_if $sig_if -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_prefix$avg_dists_list -output_file $output_p_value_summary";
  print $log_file "\n"."executing:"."\n".$produce_ps_string."\n";
  system( $produce_ps_string )==0 or die "died running command"."\n".$produce_ps_string."\n";
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
 
}



sub check_groups { # script hashes the headers from the data file and checks to see that all headers in groups have a match in the data file

  my($input_dir, $data_file, $groups_list) = @_;

  my $check_status = "All groups members match a header from the data file"; # variable to carry results of the check back to main
  my $header_hash; # declare hash for the individual headers
  
  open(DATA_FILE, "<", $input_dir."/".$data_file) or die "\n\n"."can't open DATA_FILE $data_file"."\n\n";
  
  my $header_line = <DATA_FILE>; # get the line with the column headers from the data file
  chomp $header_line;
  my @header_array = split("\t", $header_line); # place headers in an array
  shift @header_array; # shift off the first entry -- should be empty (MG-RAST) or a non essential index description (Qiime)
  
  
  #if($debug){ my $num_headers = 0; }
  foreach (@header_array){ # iterate through the array of headers and place them in a hash
    $header_hash->{$_} = 1;
    #if($debug){ $num_headers++; print STDOUT "Data Header(".$num_headers."): ".$_."\n"; }
  }
  
  my $groups_sample_counter=0;
  open(GROUPS_FILE, "<", $input_dir."/".$groups_list) or die "\n\n"."can't open GROUPS_LIST $groups_list"."\n\n"; 
  while (my $groups_line = <GROUPS_FILE>){
    chomp $groups_line;
    my @line_array = split(",", $groups_line);
    foreach (@line_array){
      $groups_sample_counter++;
      #if($debug){print STDOUT "Groups ID(".$stupid_counter."): ".$_."\n";}
      unless ( $header_hash->{$_} ){
	#$check_status = "\n"."FAIL - "."groups id: ".$_." does not exist in the data file: ";
	$check_status = $check_status."\n"."FAIL - "."groups id(".$groups_sample_counter."): ".$_." does not exist in the data file: ";
      }
    }

  }

  return $check_status;

}
