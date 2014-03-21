#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Cwd;

# takes list of names like 
# stool.1
# stool.2
# test.1
# test.2
# and generates a groups file 

my ($list_in, $groups_out, $help, $verbose, $debug);

unless ( @ARGV ) { &usage; }
unless( GetOptions (
		    "l|input_list=s"  => \$list_in,
		    "g|groups_out=s"  => \$groups_out,
		    "h|help"          => \$help,
		    "v|verbose"       => \$verbose,
		    "d|debug"         => \$debug
		   )
      ){ &usage; }

#unless( $groups_out ) { $groups_out = "my.groups.txt"; }
#unless( $list_in ) { &usage; }


sub usage {
  print qq(
DESCRIPTION: (groups_list_creator.pl)
Creates properly formatted groups file from list of sample names
sample_type.index, like this:

stool.1
stool.2
hair.1
hair.2

and will generate a groups file like this

stool.1,stool.2
hair.1,hair.2

USAGE:
      -l|--input_list   (required, no default: single column list of sample names)
      -g|--groups_out   (required, default: $groups_out)
      
      -h|--help
      -v|--verbose
      -d|--debug

);
  exit;
}

open(LIST_IN, "<", $list_in) or die "Couldn't open LIST_IN $list_in"."\n";
open(GROUPS_OUT, ">", $groups_out) or die "Couldn't open GROUPS_OUT $groups_out"."\n";

my $previous_sample_type;
my $current_sample_type;
my @output_line;

while (my $line_in = <LIST_IN>){

  chomp $line_in;
  my @line_array = split(/\./, $line_in);
  $current_sample_type = $line_array[0]; 
  
  unless ( $previous_sample_type ){ $previous_sample_type = $current_sample_type; } # do this for the first sample type encountered  
  
  if( $current_sample_type eq $previous_sample_type ){ 
    push(@output_line, $line_in);
  }else{
    my $line_out = join(",", @output_line);
    print GROUPS_OUT $line_out."\n";
    @output_line = ();
    $previous_sample_type = $current_sample_type;
    push(@output_line, $line_in);
  }
  
}

my $line_out = join(",", @output_line); # take care of last group
print GROUPS_OUT $line_out."\n";


  
