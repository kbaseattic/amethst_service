#!/usr/bin/env perl

use strict;
use warnings;

use Bio::KBase::AmethstService::Client;




my $amethst_obj = new Bio::KBase::AmethstService::Client('shocktoken' => 'fake');


my $amethst_service_version = $amethst_obj->version();


if (defined $amethst_service_version && $amethst_service_version ne '') {
	print "amethst service return version ".$amethst_service_version."\n";
	exit(0);
}

print STDERR "error: amethst service did not return version information\n";

exit(1);
