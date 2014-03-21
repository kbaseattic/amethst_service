#!/usr/bin/env perl

# script to generate the following from an abundance profile table

# THIS SCRIPT DOES NOT WORK YET - SPACE HOLDER FOR NOW

removed.raw
removed.norm
included.raw
included.norm

#use strict;
use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
use FindBin;
use File::Basename;

my $start = time;

my($data_file, $cleanup, $help, $verbose, $debug, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir);

my $output_dir = "NA";
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
		   "g|groups_list=s"   => \$groups_list,
		   "s|sig_if=s"        => \$sig_if,
		   "z|dist_pipe=s"     => \$dist_pipe,
		   "q|qiime_format=s"  => \$qiime_format,
		   "i|input_dir=s"     => \$input_dir,
		   "o|output_dir=s"    => \$output_dir,
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
