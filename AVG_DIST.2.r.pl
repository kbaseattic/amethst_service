#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Cwd;


my ($avg_dist_file, $debug);

my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;
# date +%m-%d-%y_%H:%M:%S:%N month-day-year_hour:min:sec:nanosec

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $avg_dist_file ) { &usage(); }

if ( ! GetOptions (
		   "f|data_file=s" => \$avg_dist_file,
		   "d|debug!"        => \$debug
		  )
   ) { &usage(); }


my $output_file = $avg_dist_file.".r_formatted";


open(FILE_IN, "<", $avg_dist_file) or die "Couldn't open FILE_IN $avg_dist_file"."\n";
open(FILE_OUT, ">", $output_file) or die "Couldn't open FILE_OUT $output_file"."\n";


while (my $line = <FILE_IN>){          
  
  chomp $line;
  
  unless ($line =~ m/^\t|^\s|^#|^>|^_|^-/){
    print FILE_OUT $line."\n";
  }
  
}

system(`sort -u $output_file > $output_file.u_sorted`)==0 or die "died running sort";

sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $time_stamp
script:               $0

DESCRIPTION:
Convert *.AVG_DIST files to a form that R can use to quickly plot
   
USAGE:
    -f|--avg_dist_file
    -----------------------------------------------------------------------------------------------
    -d|--debug            (flag)       run in debug mode

);
  exit 1;
}
