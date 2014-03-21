#!/usr/bin/env perl


#use strict;
use warnings;
use Getopt::Long;
use Cwd;

my $start_time_stamp = `date +%m-%d-%y_%H:%M:%S`;
chomp $start_time_stamp;

my ($target_dir, $unzip, $help, $verbose, $debug);
my $input_pattern = ".P_VALUE_SUMMARY\$";
my $output_pattern;
my $current_dir = getcwd()."/";
my($group_name, $raw_dist, $group_dist_stdev, $scaled_dist, $dist_p, $num_perm, $group_members);
#my $raw_dists_out ="";

#if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

# check input args and display usage if not suitable
unless($go){if ( @ARGV==0 ) { &usage(); }}
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

#unless ( @ARGV > 0 || $data_file ) { &usage(); }

if ( ! GetOptions (
		   "d|target_dir=s"     => \$target_dir,
		   "u|unzip!"           => \$unzip,
		   "i|input_pattern=s"  => \$input_pattern,
		   "o|output_pattern=s" => \$output_pattern,
		   "g|go!"              => \$go,
		   "h|help!"            => \$help, 
		   "v|verbose!"         => \$verbose,
		   "b|debug!"           => \$debug
		  )
   ) { &usage(); }


unless ($target_dir) {$target_dir = $current_dir;} # use current directory if no other is supplied
#unless ($output_pattern) {$output_pattern = "my_compiled.P_VALUES_SUMMARY.".$start_time_stamp;}
unless ($output_pattern) {$output_pattern = "my_compiled.P_VALUES_SUMMARY";}
#if($debug){print STDOUT "\n\n\noutput_pattern: ".$output_pattern."\n\n\n"}

if ( $unzip ){
  #system("ls *.tar.gz > tar_list.txt")==0 or die "died listing *.tar.gz";  
  system('for i in *tar.gz; do tar -zxf $i; done')==0 or die "died unzipping *.tar.gz listed in tar_list.txt";
}


# create output files
open(OUTPUT_RAW_DISTS, ">",       $target_dir.$output_pattern.".raw_avg_dist") or die "can't open OUTPUT_RAW_DISTS";
open(OUTPUT_RAW_DISTS_STDEV, ">", $target_dir.$output_pattern.".raw_avg_dist_stdev") or die "can't open OUTPUT_RAW_DISTS_STDEV";
open(OUTPUT_SCALED_DISTS, ">",    $target_dir.$output_pattern.".scaled_avg_dist") or die "can't open OUTPUT_SCALED_DISTS";
open(OUTPUT_P_VALUES, ">",        $target_dir.$output_pattern.".p_values") or die "can't open OUTPUT_P_VALUES";
open(OUTPUT_NUM_PERM, ">",        $target_dir.$output_pattern.".num_perm") or die "can't open OUTPUT_NUM_PERM";

# Start the header strings
my $raw_dists_header = "RAW_DISTS"."\n"."input_file";
my $group_dists_stdev_header = "RAW_DISTS_STDEV"."\n"."input_file";
my $scaled_dists_header = "SCALED_DISTS"."\n"."input_file";
my $dist_ps_header = "p's"."\n"."input_file";
my $num_perms_header = "NUM_PERMS"."\n"."input_file";
      
# read input file names into array
@file_list = &list_dir($target_dir, $input_pattern);  

my $file_counter = 0;
foreach my $file (@file_list){ # process each file 
  #if($debug){print STDOUT "\n".$file;}
 
 # initialize outputs
  my $raw_dists_out = $file;
  my $raw_dists_stdevs_out = $file;
  my $scaled_dists_out = $file;
  my $dist_ps_out = $file;
  my $num_perms_out = $file;
  
  open(FILE, "<", $target_dir.$file) or die "can't open FILE $target_dir.$file"; 
  while (my $line = <FILE>){
    
    unless ($line =~ m/^#/){ # skip comment lines
      #if($debug){print STDOUT $line;}
      chomp $line;
      if($debug){print STDOUT "LINE: ".$line."\n";}
      my @line_array = split("\t", $line);
      $group_name = $line_array[0];
      if($debug){print STDOUT "\n"."group_name:"."\t".$group_name."\n";}
      
      # parse data from line
      $raw_dist = $line_array[1];
      $group_dist_stdev = $line_array[2];
      $scaled_dist = $line_array[3];
      $dist_p = $line_array[4];
      $num_perm = $line_array[5];
      $group_members = $line_array[6];

      # add data to output
      $raw_dists_out = $raw_dists_out."\t".$raw_dist;
      $raw_dists_stdevs_out = $raw_dists_stdevs_out."\t".$group_dist_stdev;
      $scaled_dists_out = $scaled_dists_out."\t".$scaled_dist;
      $dist_ps_out = $dist_ps_out."\t".$dist_p;
      $num_perms_out = $num_perms_out."\t".$num_perm;
 
      #if($debug){print STDOUT "\nraw_dists: ".$raw_dists_out;}
      
      # complete the header strings when reading through the first file
      if ($file_counter == 0) {

	$raw_dists_header = $raw_dists_header."\t".$group_name." :: ".$group_members;
	$group_dists_stdev_header = $group_dists_stdev_header."\t".$group_name." :: ".$group_members;
	$scaled_dists_header = $scaled_dists_header."\t".$group_name." :: ".$group_members;
	$dist_ps_header = $dist_ps_header."\t".$group_name." :: ".$group_members;
	$num_perms_header = $num_perms_header."\t".$group_name." :: ".$group_members;

      }

      #if($debug){print STDOUT "\n".$raw_dists_header; }

    }
    

  }
 
 if ($file_counter == 0){ # print the headers
    print OUTPUT_RAW_DISTS $raw_dists_header."\n";
    print OUTPUT_RAW_DISTS_STDEV $group_dists_stdev_header."\n";
    print OUTPUT_SCALED_DISTS $scaled_dists_header."\n";
    print OUTPUT_P_VALUES $dist_ps_header."\n";
    print OUTPUT_NUM_PERM $num_perms_header."\n";
  }

  #print the data
  print OUTPUT_RAW_DISTS $raw_dists_out."\n";
  print OUTPUT_RAW_DISTS_STDEV $raw_dists_stdevs_out."\n";
  print OUTPUT_SCALED_DISTS $scaled_dists_out."\n";
  print OUTPUT_P_VALUES $dist_ps_out."\n";
  print OUTPUT_NUM_PERM $num_perms_out."\n";
  $file_counter++;

}
    

# if ($file_counter == 0){ # print headers
      
#       $raw_dists_header = 


      
# 		$file_counte++

# 	      }


#    OUTPUT_RAW_DISTS, ">",       $target_dir.$output_pattern.".raw_avg_dist");
# OUTPUT_RAW_DISTS_STDEV, ">", $target_dir.$output_pattern.".raw_avg_dist_stdev");
# OUTPUT_SCALED_DISTS, ">",    $target_dir.$output_pattern.".scaled_avg_dist");
# OUTPUT_P_VALUES, ">",        $target_dir.$output_pattern.".p_values");
# OUTPUT_NUM_PERM, 




#     # check to make sure line is parsed properly
#     if($debug){print STDOUT qq (
# file:          $file
# group_name:    $group_name
# raw_dist:      $raw_dist
# stdev:         $group_dist_stdev
# scaled_dist:   $scaled_dist
# p:             $dist_p
# num_perm:      $num_perm
# group members: $group_members
# 			    );
# 	     }




#while (my $line = <DATA_FILE>){          
#  $line =~ s/\r\n|\n\r|\n|\r/\n/g;  #get rid of the line ends that are there
#  print TEMP_FILE $line; #replace them with \n
#}



#open(BIOM_FILE_LIST, "<", $biom_file_list)










sub list_dir {
  
  my($dir_name, $list_pattern) = @_;
  
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  closedir DIR or die "can't close DIR";
  
  my @filtered_dir_files_list;
  while (my $dir_object = shift(@dir_files_list)) {
    $dir_object =~ s/^\.//;
    push(@filtered_dir_files_list, $dir_object);
    #print "DIR  ".$dir_name.$dir_object."\n";
  }
  
  return @filtered_dir_files_list;
  
}





# sub list_dir {
  
#   my($dir, $pattern) = @_;
  
#   #open(DIR_LIST, ">", $dir_list) or die "\n\n"."can't open DIR_LIST $dir_list"."\n\n";
#   opendir(DIR, $dir) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
#   my @dir_list = grep /$pattern/, readdir DIR; or die "\n\n"."can't read DIR $dir"."\n\n";
#   #print DIR_LIST join("\n", @dir_list); print DIR_LIST "\n";
#   closedir DIR;
#   return(@dir_list)
  
# }




sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $start_time_stamp
script:               $0

USAGE:
compile_p-values-summary_files -d|--dir_path <dir path> -i|--input_pattern <input pattern> -o|--output_prefix <output prefix>

     -d|--dir_path        default = $current_dir
                          string - path for directory with files (default is current directory)

     -i|--input_pattern   default = $input_pattern
                          pattern or extension to match at the end of the files

     -o|--output_prefix   default = $output_pattern
                          prefix for the output files

     -g|--go              run with all default values

     -u|--unzip           flag to unzip any *.tar.gz before proceeding

     -h|--help
     -v|--verbose
     -b|--debug

DESCRIPTION:
This script will produce summary outputs from multiple *.P_VALUES_SUMMARY files
produced from AMETHST.pl, or any of the individual scripts that it 
drives:

     plot_pco_with_stats,
     plot_qiime_pco_with_stats,
     plot_OTU_pco_with_stats, or
     plot_pco_with_stats_all

The script produces 5 output files that contain the:

     output_pattern.raw_avg_dist        # the raw average distances calculated for each within/between group analysis
     output_pattern.raw_avg_dist_stdev  # standard deviations for the raw average distances
     output_pattern.scaled_avg_dist     # average distances scaled from 0 to 1
     output_pattern.p_values            # p value for each within/between group average distance
     output_pattern.num_perm            # number of permutations used to generate the p values

The only argument is the path for the directory that contains the *.P_VALUES_SUMMARY
files. The default path is "./".
   
);
  exit 1;
}
