#!/usr/bin/env perl

#use strict;

# 1-14-13 note -- at least one of these conversions leaves an errant emty line at the
# beginning of the generated output

use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
use FindBin;
use File::Basename;

my($input_file, $help, $verbose, $debug);

my $current_dir = getcwd()."/";
my $conversion = 1;
my $output_file_pattern;

if($debug){print STDOUT "made it here"."\n";}

# path of this script
#my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles
my $DIR="$FindBin::Bin/";

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $input_file ) { &usage(); }

if ( ! GetOptions (
		   "i|input_file=s"               => \$input_file,
		   "o|output_file=s"              => \$output_file_pattern,
		   "c|conversion=i"               => \$conversion,
		   "h|help!"                      => \$help, 
		   "v|verbose!"                   => \$verbose,
		   "d|debug!"                     => \$debug
		  )
   ) { &usage(); }

##################################################
##################################################
###################### MAIN ######################
##################################################
##################################################

unless ($output_file_pattern){
  $output_file_pattern = $input_file;
}

if ($conversion == 1){
  &format_table_qiime_2_R($input_file, $output_file_pattern.".tax_string.R_table");
}elsif ($conversion == 2) {
  format_table_qiime_2_R_qiime_ID($input_file, $output_file_pattern.".qiime_ID.R_table");
}elsif ($conversion == 3) {
  format_table_qiime_2_R_qiime_ID_and_tax($input_file, $output_file_pattern.".qiime_ID_and_tax_string.R_table");
}elsif ($conversion == 4) {
  &format_table_R_2_qiime($input_file, $output_file_pattern.".arbitrary_index.Qiime_table");
}elsif ($conversion == 5) {
  format_table_R_2_qiime_with_prepended_qiime_IDs($input_file, $output_file_pattern.".qiime_index.Qiime_table")
}else{
  print STDOUT "$conversion is not a valid conversion"."\n\n";
  &usage();
}

##################################################
##################################################
###################### SUBS ######################
##################################################
##################################################

sub format_table_qiime_2_R { # creates an R_formatted version of a qiime table format (NOT biom)

  my ($qiime_table_in, $R_table_out) = @_;

  my $file_check = `file $qiime_table_in`;   #check line terminators -- correct if needed
  if ( $file_check =~ m/long/ ) {
    system("$DIR/line_term.pl -i $qiime_table_in -o $qiime_table_in.lt_edit; mv $qiime_table_in.lt_edit $qiime_table_in")==0 or die "died runnin line_term.pl";
  } 
  
  my $last_header_line_in = ''; # script assumes that there may be multiple comment lines before header line
  my $header_line_out = '';
  my @out_lines;
  
  open(QIIME_TABLE, "<", $qiime_table_in) or die "Can't open QIIME_TABLE $qiime_table_in";
  
  while ( my $line = <QIIME_TABLE> )  {
  
    chomp $line;
   
    if ( $line =~ m/^#/ ) { 

      $last_header_line_in = $line; 
   
    } else { # skip lines that start with #, assume last one has the column headers

      my @header_array = split("\t", $last_header_line_in); # print the last line of the qiime header in R format
      pop @header_array; # pop off the last field
      my $qiime_id = shift @header_array; # shift off the first field (qiime format, 0-based integer index)
      $header_line_out = ""."\t".(join("\t", @header_array));
      
      my @line_array = split("\t", $line);
      shift @line_array; # shift off the first field (qiime format, 0-based integer index)
      my $row_label = pop @line_array; 
      push(@out_lines, $row_label."\t".join("\t", @line_array)) #store new data lines in array until print

    }

  }

  open(R_TABLE_OUT, ">", $R_table_out) or die "Can't open R_TABLE_OUT $R_table_out";
  print R_TABLE_OUT $header_line_out."\n".join("\n",@out_lines)."\n"; # print R formatted data to file

}


sub format_table_qiime_2_R_qiime_ID { # creates an R_formatted version of a qiime table format (NOT biom)

  my ($qiime_table_in, $R_table_out) = @_;

  my $file_check = `file $qiime_table_in`;   #check line terminators -- correct if needed
  if ( $file_check =~ m/long/ ) {
    system("$DIR/line_term.pl -i $qiime_table_in -o $qiime_table_in.lt_edit; mv $qiime_table_in.lt_edit $qiime_table_in")==0 or die "died running line_term.pl";
  } 
  
  my $last_header_line_in = ''; # script assumes that there may be multiple comment lines before header line
  my $header_line_out = '';
  my @out_lines;
  
  open(QIIME_TABLE, "<", $qiime_table_in) or die "Can't open QIIME_TABLE $qiime_table_in";
  
  while ( my $line = <QIIME_TABLE> )  {
  
    chomp $line;
   
    if ( $line =~ m/^#/ ) { 

      $last_header_line_in = $line; 
   
    } else { # skip lines that start with #, assume last one has the column headers

      my @header_array = split("\t", $last_header_line_in); # print the last line of the qiime header in R format
      pop @header_array; # pop off the last field
      shift @header_array; # shift off the first field (qiime format, 0-based integer index)
      #my $qiime_id = shift @header_array; # shift off the first field (qiime format, 0-based integer index)
      $header_line_out = ""."\t".(join("\t", @header_array));
      
      my @line_array = split("\t", $line);
      my $qiime_id = shift @line_array; # shift off the first field (qiime format, 0-based integer index)
      #my $row_label = pop @line_array;
      pop @line_array;
      push(@out_lines, "id".$qiime_id."\t".join("\t", @line_array)) #store new data lines in array until print

    }

  }

  open(R_TABLE_OUT, ">", $R_table_out) or die "Can't open R_TABLE_OUT $R_table_out";
  print R_TABLE_OUT $header_line_out."\n".join("\n",@out_lines)."\n"; # print R formatted data to file

}



sub format_table_qiime_2_R_qiime_ID_and_tax { # creates an R_formatted version of a qiime table format (NOT biom)

  my ($qiime_table_in, $R_table_out) = @_;

  my $file_check = `file $qiime_table_in`;   #check line terminators -- correct if needed
  if ( $file_check =~ m/long/ ) {
    system("$DIR/line_term.pl -i $qiime_table_in -o $qiime_table_in.lt_edit; mv $qiime_table_in.lt_edit $qiime_table_in")==0 or die "died running line_term.pl";
  } 
  
  my $last_header_line_in = ''; # script assumes that there may be multiple comment lines before header line
  my $header_line_out = '';
  my @out_lines;
  
  open(QIIME_TABLE, "<", $qiime_table_in) or die "Can't open QIIME_TABLE $qiime_table_in";
  
  while ( my $line = <QIIME_TABLE> )  {
  
    chomp $line;
   
    if ( $line =~ m/^#/ ) { 

      $last_header_line_in = $line; 
   
    } else { # skip lines that start with #, assume last one has the column headers

      my @header_array = split("\t", $last_header_line_in); # print the last line of the qiime header in R format
      pop @header_array; # pop off the last field
      shift @header_array; # shift off the first field (qiime format, 0-based integer index)
      #my $qiime_id = shift @header_array; # shift off the first field (qiime format, 0-based integer index)
      $header_line_out = ""."\t".(join("\t", @header_array));
      
      my @line_array = split("\t", $line);
      my $qiime_id = shift @line_array; # shift off the first field (qiime format, 0-based integer index)
      my $row_label = pop @line_array;
      push(@out_lines, "id".$qiime_id.";".$row_label."\t".join("\t", @line_array)) #store new data lines in array until print

    }

  }

  open(R_TABLE_OUT, ">", $R_table_out) or die "Can't open R_TABLE_OUT $R_table_out";
  print R_TABLE_OUT $header_line_out."\n".join("\n",@out_lines)."\n"; # print R formatted data to file
  #print R_TABLE_OUT join("\n",@out_lines)."\n"; # print R formatted data to file
  
  #if ($debug) {print STDOUT "header_line_out:".$header_line_out."\n";}


}



sub format_table_R_2_qiime { # script assumes just one line of header for R format

  my ($R_table_in, $qiime_table_out) = @_;

  my $file_check = `file $R_table_in`;   #check line terminators -- correct if needed
  if ( $file_check =~ m/long/ ) {
    system("$DIR/line_term.pl -i $R_table_in -o $R_table_in.lt_edit; mv $R_table_in.lt_edit $R_table_in")==0 or die "died running line_term.pl";
  }

  open(R_TABLE_IN, "<", $R_table_in) or die "Can't open R_TABLE_IN $R_table_in"; 

  my $header_line_in = <R_TABLE_IN>; # first line is the header
  chomp $header_line_in;
  my @header_line_in_array = split("\t", $header_line_in);
  shift @header_line_in_array;
  my $header_line_out = "#ID"."\t".join("\t", @header_line_in_array)."\t"."Row_Label";

  my $line_counter = 0;
  my @out_lines;

  while ( my $line = <R_TABLE_IN> )  { # every other line (except last empty) has counts

    unless ( $line =~ /^\s*$/ ) {

      chomp $line;

      my @line_array = split("\t", $line);
      my $row_label = shift(@line_array);
      my $qiime_line = $line_counter."\t".join("\t", @line_array)."\t".$row_label;
      push(@out_lines, $qiime_line);
      $line_counter++;

    }
  
  }

  open(QIIME_TABLE_OUT, ">", $qiime_table_out) or die "Can't open QIIME_TABLE_OUT $qiime_table_out";
  print QIIME_TABLE_OUT $header_line_out."\n".join("\n",@out_lines);
  
}



sub format_table_R_2_qiime_with_prepended_qiime_IDs { # script assumes just one line of header for R format

  # Note: 1-14-13; this conversion cut the last column of data out, fixed below

  my ($R_table_in, $qiime_table_out) = @_;

  my $file_check = `file $R_table_in`;   #check line terminators -- correct if needed
  if ( $file_check =~ m/long/ ) {
    system("$DIR/line_term.pl -i $R_table_in -o $R_table_in.lt_edit; mv $R_table_in.lt_edit $R_table_in")==0 or die "died running line_term.pl";
  }

  open(R_TABLE_IN, "<", $R_table_in) or die "Can't open R_TABLE_IN $R_table_in"; 

  my $header_line_in = <R_TABLE_IN>; # first line is the header

  if($debug){ print STDOUT "HEADER LINE:"."\n".$header_line_in."\n\n"; }

  chomp $header_line_in;
  my @header_line_in_array = split("\t", $header_line_in);
  shift @header_line_in_array;
  my $header_line_out = "#ID"."\t".join("\t", @header_line_in_array)."\t"."Tax_string";

  #my $line_counter = 0;
  my @out_lines;

  while ( my $line = <R_TABLE_IN> )  { # every other line (except last empty) has counts

    unless ( $line =~ /^\s*$/ ) {

      chomp $line;

      my @line_array = split("\t", $line);
      my $row_lable = shift(@line_array);
      my @label_array = split(";", $row_lable);
      my $qiime_id = shift(@label_array);
      $qiime_id =~ s/^id//; # if the ID has the "id" prefix, remove it
      my $qiime_tax_string = join(";",@label_array);
      my $qiime_line = $qiime_id."\t".join("\t", @line_array)."\t".$qiime_tax_string;
      push(@out_lines, $qiime_line);
      #$line_counter++;

    }
  
  }

  open(QIIME_TABLE_OUT, ">",$qiime_table_out) or die "Can't open QIIME_TABLE_OUT $qiime_table_out";
  print QIIME_TABLE_OUT $header_line_out."\n".join("\n",@out_lines);
  
}



sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

DESCRIPTION:
Script to convert qiime table (pre biom format table) to R friendly format 
or vice versa.  The script assumes that qiime format files will have one 
or more lines of comment (#); the last comment line is assumed to contain
the headers.  It assumes that the first line of R formatted files contains
the header.
   
USAGE: qiime_2_R.pl [-i input_file] [-o output_file_pattern] [-c conversion]

    -i|input_file                 (string)  NO DEFAULT
                                              original data file

    -o|output_file_pattern        (string)  default = -input_file
                                              The outputfile will be name as
                                                   output_file_pattern.R_table(...) or
                                                   output_file_pattern.Qiime_table(...)

    -c|conversion                 (int)     default = $conversion
                                                   1 convert qiime to R - index by tax string
                                                   2 convert qiime to R - index by qiime id 
                                                   3 convert qiime to R - index by qiime id and
                                                     tax string: qiime_id;tax1;... 
 
                                                   4 convert R to qiime with arbitrary IDs
                                                   5 convert R to qiime with qiime IDs
                                                     (Note: input to 5 must be output from 3)

 _______________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}

