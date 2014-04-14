#!/usr/bin/env perl

use strict;
use warnings;


sub find_amethst_bin_dir {
	my $KB_TOP = $ENV{'KB_TOP'};
	
	unless (defined $KB_TOP) {
		die "KB_TOP not defined";
	}
	
	if ($KB_TOP eq '') {
		die "KB_TOP not defined";
	}
	
	unless (-d $KB_TOP ) {
		die "KB_TOP directory \"$KB_TOP\" not found";
	}
	
	my $service_dir = $KB_TOP.'/services/amethst_service/';
	
	unless (-d $service_dir ) {
		die "AMETHST service directory \"$service_dir\" not found";
	}
	
	my $amethst_bin_dir = $service_dir.'AMETHST/';
	
	
	unless (-d $amethst_bin_dir ) {
		die "AMETHST bin directory \"$amethst_bin_dir\" not found";
	}
	return $amethst_bin_dir;
}



my $amethst_pl = find_amethst_bin_dir().'AMETHST.pl';


unless (-e $amethst_pl) {
	die "\"$amethst_pl\" not found";
}

system($amethst_pl." -h") == 0 or die "$amethst_pl returned with error";

return 0;



