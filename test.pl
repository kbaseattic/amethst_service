#!/usr/bin/env perl

print "\n\n";

my $string = "unifrac_16.Qiime.100p.included.norm.qiime_table.qiime_ID_and_tax_string.R_table.permutation.9.qiime_index.Qiime_table.txt";

chomp $string;

my @array = split(/\./, $string);
print "string:     ".$string."\n";
print "array:      ".@array."\n";
print scalar(@array)."\n";
pop(@array);
print scalar(@array)."\n";
push(@array, "DIST");
print scalar(@array)."\n";
my $new_string = join(".", @array);
print "string:     ".$string."\n";
print "array:      ".@array."\n";
print "new_string: ".$new_string."\n";
