#!/usr/bin/env perl

#use strict;
use warnings;
use Getopt::Long;
use Cwd;
use Statistics::Descriptive;

my($og_avg_dist_file, $help, $verbose, $debug);

my $avg_dists_dir = "./AVG_DISTs/";

my $avg_dists_list = "AVG_DISTs_list";

my $sig_if = "lt";

my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;
my $output_file = "P_SUMMARY";

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $og_avg_dist_file ) { &usage(); }

if ( ! GetOptions (
		   "og_avg_dist_file=s" => \$og_avg_dist_file,
                   "sig_if=s"           => \$sig_if,
		   "avg_dists_dir=s"    => \$avg_dists_dir,
		   "avg_dists_list=s"   => \$avg_dists_list,
		   "output_file=s"      => \$output_file,
		   "help!"              => \$help, 
		   "verbose!"           => \$verbose,
		   "debug!"             => \$debug
		  )
   ) { &usage(); }

open(OUTPUT, ">", $output_file) or die "could not open OUTPUT $output_file";
print OUTPUT (
	      "##### avg_dist_summary output #####"."\n".
	      "##### time stamp:         ".$time_stamp."\n".
	      "##### original dist file: ".$og_avg_dist_file."\n".
	      "##### avg_dist_dir:       ".$avg_dists_dir."\n".
	      "#########################################################"."\n".
	      "# dist description"."\t"."og_dist_avg"."\t"."og_dist_stdev"."\t"."og_dist_avg.scaled"."\t"."og_dist_P"."\t"."num_permutations"."\t"."other notes"."\n"
	     );

my @ordered_keys;

my $og_dist_avg_hash = {};
my @og_dist_avg_array; # NEW 8-24-12
my $og_dist_stdev_hash = {};
my $og_dist_members_hash = {};
my $perm_sum_dist_avg_hash = {};
my @og_line_array;


#$debug = 1;

open(OG_FILE, "<", $og_avg_dist_file) or die "cannot open OG_FILE $og_avg_dist_file";

my $line_num = 0;

while (my $og_line = <OG_FILE>){
  
  $line_num++;
     
  if ( $og_line =~ m/->/ ){

    chomp $og_line;
    @og_line_array = split("\t", $og_line);

    push(@ordered_keys, $og_line_array[0]);
    $og_dist_avg_hash->{$og_line_array[0]} = $og_line_array[1];
    $perm_sum_dist_avg_hash->{$og_line_array[0]} = 0;# added this line 1-11-13 -- problem, keys with a sum of zero perms < original were not entered
    if($debug){ print STDOUT "ID from original file: ".$og_line_array[0]."\n"; }
    push(@og_dist_avg_array, $og_line_array[1]); # NEW 8-24-12
    $og_dist_stdev_hash->{$og_line_array[0]} = $og_line_array[3];
    if($og_line_array[4]){
      $og_dist_members_hash->{$og_line_array[0]} = $og_line_array[4]
    }else{
      $og_dist_members_hash->{$og_line_array[0]} = "group_members=(see individual groups above)"
    }
    
  }

}

close(OG_FILE) or die "could not close OG_FILE $og_avg_dist_file";



my @avg_dist_list; # grab the names of the *.AVG_DIST files from the AVG_DISTs_list
my $num_perm_dl = 0;
open(AVG_DIST_LIST, "<", $avg_dists_list) or die "cannot open AVG_DIST_LIST $avg_dists_list";
while (my $avg_dist_list_line = <AVG_DIST_LIST>){
  chomp $avg_dist_list_line;
  push(@avg_dist_list, $avg_dist_list_line);
}
$num_perm_dl = scalar(@avg_dist_list);



foreach my $perm (@avg_dist_list){

  open(AVG_DIST_FILE, "<", $avg_dists_dir.$perm) or die "cannot open PERM_FILE $perm";

  while (my $perm_line = <AVG_DIST_FILE>){
    
    if ( $perm_line =~ m/->/ ){
      chomp $perm_line;

      my @perm_line_array = split("\t", $perm_line);
      my $perm_line_key = $perm_line_array[0];
     
      if ($sig_if eq "lt"){
	if ( $perm_line_array[1] < $og_dist_avg_hash->{$perm_line_array[0]} ){
	  $perm_sum_dist_avg_hash->{$perm_line_array[0]}++;
	}
      }elsif($sig_if eq "gt"){
	if ( $perm_line_array[1] > $og_dist_avg_hash->{$perm_line_array[0]} ){
	  $perm_sum_dist_avg_hash->{$perm_line_array[0]}++;
	}
      }else{
	print STDOUT "\n\n"."invalid sig_if value ( ".$sig_if." )"."\n"."value must be \"lt\" or \"gt\""."\n\n";
	exit 1;
      }	
      
    }
  }
  close(AVG_DIST_FILE) or die "could not close AVG_DIST_FILE $avg_dists_dir.$perm";
}


##### NEW 8-24-12 #####
# Get the min and max average distances so I can scale them below
my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@og_dist_avg_array);
#my $min_og_dist_avg = sprintf "%.4f", $stat->min();
#my $max_og_dist_avg = sprintf "%.4f", $stat->max();
my $min_og_dist_avg = $stat->min();
my $max_og_dist_avg = $stat->max();
#######################


my @p_value_array; # added 8-24-12
foreach my $ordered_key (@ordered_keys){
  my $og_dist_avg = $og_dist_avg_hash->{$ordered_key};
  my $og_dist_stdev = $og_dist_stdev_hash->{$ordered_key}; # can be NA
  my $num_perm_lt_real = $perm_sum_dist_avg_hash->{$ordered_key}; # can be empty
  my $p_value;
  unless($num_perm_dl){print STDOUT exit "num_perm (".$num_perm_dl.") is missing in avg_dist_summary.pl"."\n";}
  if($debug){ print STDOUT "ID from perm:          ".$ordered_key."\n"; }
  
  unless (defined $perm_sum_dist_avg_hash->{$ordered_key} ){
    $p_value = "NA"; # report NA if the key was not encoutered, such an occurence is an error 1-11-13
  }else{    
    if ( $perm_sum_dist_avg_hash->{$ordered_key} == 0 ){
      $p_value = (1/$num_perm_dl); # p is 1/num_perm if no perm had dists < real_data
    }else{
      $p_value = ( $perm_sum_dist_avg_hash->{$ordered_key}/$num_perm_dl ); # p = ( (num_perm with dists) > real_data /(num_perm) )
    }
  }
  my $sample_names = $og_dist_members_hash->{$ordered_key};
  
  push(@p_value_array, $p_value);

  if($min_og_dist_avg < 0){die "\n\n\n"."Min distance (".$min_og_dist_avg.") < 0 , you have to fix the code ^_^"."\n\n\n";}
  if($max_og_dist_avg < 0){die "\n\n\n"."Max distance (".$max_og_dist_avg.") < 0 , you have to fix the code ^_^"."\n\n\n";}
  
  print OUTPUT $ordered_key."\t".$og_dist_avg."\t".$og_dist_stdev."\t".(($og_dist_avg-$min_og_dist_avg)/($max_og_dist_avg-$min_og_dist_avg))."\t".$p_value."\t".$num_perm_dl."\t".$sample_names."\n"; # went back to this and correct earlier 1-11-13

}

##### NEW 8-24-12 #####
# Get the mean and stdev of p values and print them at the bottom of the output file
my $stat2 = Statistics::Descriptive::Full->new();
$stat2->add_data(@p_value_array);
#my $mean_p_value = sprintf "%.4f", $stat2->mean();
#my $stdev_p_value = sprintf "%.4f", $stat2-> standard_deviation();
my $mean_p_value = $stat2->mean();
my $stdev_p_value = $stat2-> standard_deviation();

print OUTPUT "# Mean_p_value:"."\t"."\t"."\t"."\t".$mean_p_value."\n"; # extra tabs are to place avg p under all other p's
print OUTPUT "# Stdev_p_value:"."\t"."\t"."\t"."\t".$stdev_p_value."\n"; # extra tabs are to place avg p under all other p's
#######################



############### SUBS ###############



sub list_dir {

  my($dir_name, $list_pattern, $dir_list) = @_;
  
  open(DIR_LIST, ">", $dir_list) or die "\n\n"."can't open DIR_LIST $dir_list"."\n\n";
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  print DIR_LIST join("\n", @dir_files_list); print DIR_LIST "\n";
  closedir DIR or die "could not close DIR $dir_name";
  
}



### Subs ###
sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $time_stamp
script:               $0
num supplied args:    $num_args

DESCRIPTION:
Produce P values from original and permutation derived *.AVG_DIST files.
Be very careful to select the correct setting for sig_if -- details below:
   
USAGE:

               
    --og_avg_dist_file (string) NO DEFAULT               : path and filename of the original (non-permuted) *.AVG_DIST file

    --sig_if           (string) default = $sig_if        : lt or gt - determines if permutation distances less or greater than 
                                                           original are deemed significant

                                                           The default \"lt\" is appropriate for determination of significance
                                                           within a group -- distances are significant if they are less than
                                                           that observed in the real data. Permutations would be expected to 
                                                           exhibit within group distances larger than the original.
                                                           We expect the opposite behvaior for between group distances; \"gt\" is 
                                                           appropriate for determination of significance between groups.
                                                           Permutations would be expected to exhibit between group distances
                                                           smaller than those observed in the original.  

    --avg_dists_dir    (string) default = $avg_dists_dir : path where the permutation *.AVG_DIST files can be found

    --avg_dists_list   (string) default = $avg_dists_list : path/file for the list of files in AVG_DISTS dir

    --output_file      (string) default = "P_SUMMARY"    : name (or path and name) for the output file
     
    -----------------------------------------------------------------------------------------------------------------------
    --help             (flag)                            : see the help/usage
    --verbose          (flag)                            : run in verbose mode
    --debug            (flag)                            : run in debug mode

);
  exit 1;
}
