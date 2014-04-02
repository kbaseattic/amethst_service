#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use File::Slurp;
use Config::Simple;
use Data::Dumper;

use File::Basename;

use SHOCK::Client; # needed for download of results from shock
use USAGEPOD qw(parse_options);






#my $aweserverurl =  $ENV{'AWE_SERVER_URL'};
my $shockurl =  $ENV{'SHOCK_SERVER_URL'};
#my $clientgroup = $ENV{'AWE_CLIENT_GROUP'};

my $shocktoken=$ENV{'KB_AUTH_TOKEN'};


##############################################

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

sub read_shock_url {
	
	my $conf_file = $ENV{'KB_TOP'}.'/deployment.cfg';
	unless (-e $conf_file) {
		die "error: deployment.cfg not found ($conf_file)";
	}
	
	
	my $cfg_full = Config::Simple->new($conf_file );
	my $cfg = $cfg_full->param(-block=>'AmethstService');
	
	my $shockurl =  $cfg->{'shock-server'};
	
	unless (defined($shockurl) && $shockurl ne "") {
		die "shockurl not found in config";
	}
	
	return $shockurl;
}


##############################################

my ($h, $help_text) = &parse_options (
'name' => 'mg-amethst -- wrapper for amethst',
'version' => '1',
'synopsis' => 'mg-amethst -c <commandsfile>',
'examples' => 'ls',
'authors' => 'Wolfgang Gerlach',
'options' => [
'workflow submission:',
#[ 'matrix|m=s',	"abundance matrix"],
#[ 'groups|g=s',	"groups file" ],
[ 'commands|c=s',	"commands file" ],
#[ 'tree|t=s',		"tree (optional)" ],
[ 'token=s',	"shock token" ],
'',
'other commands:',
[ 'status|s=s' ,	'show status of a given AWE job_id'],
[ 'download|d=s' ,	'download results for a given AWE job_id'],
[ 'delete=s' ,		'delete AWE Job (and SHOCK files) for a given AWE job_id'],
'',
'only local: (bypasses service)',
[ 'command_file|f=s', ""],
[ 'zip_prefix|z=s', ""],
[ 'output_zip=s', ""],
[ 'summary', "" ],
'',
[ 'nosubmit', "just list files, do not upload or submit to service"],
[ 'local', "", { hidden => 1  }], #deprecated
[ 'help|h', "", { hidden => 1  }]
]
);


if ($h->{'help'} || keys(%$h)==0) {
	print $help_text;
	exit(0);
}


if (defined $h->{'token'}) {
	$shocktoken = $h->{'token'};
}

if (defined($shocktoken) && $shocktoken eq '') {
	$shocktoken = undef;
}

my $job_id = undef;
if ((defined $h->{'command_file'}) || (defined $h->{'zip_prefix'}) ) {
	
	
	$h->{'command_file'} || die "no command_file defined";
	$h->{'zip_prefix'} || die "no zip_prefix defined";
	
	
	
	my $amethst_pl = find_amethst_bin_dir().'AMETHST.pl';
	
	
	unless (-e $amethst_pl) {
		die "\"$amethst_pl\" not found";
	}
	
	#print "found $amethst_pl\n";
	
	my $cmd = $amethst_pl.' -f '.$h->{'command_file'}.' -z '.$h->{'zip_prefix'};
	print "cmd: $cmd\n";
	system($cmd);

} elsif ( defined $h->{'summary'} ) {
	
	my $summary_pl = find_amethst_bin_dir().'compile_p-values-summary_files.pl';
	
	
	unless (-e $summary_pl) {
		die "\"$summary_pl\" not found";
	}
	
	my $cmd = $summary_pl.' -g -u -s';
	
	if (defined $h->{'output_zip'}) {
		$summary_pl .= ' '.$h->{'output_zip'};
	}
	
	
	print "cmd: $cmd\n";
	system($cmd);
	
	
	
} elsif ( defined($h->{'commands'}) ) {
	
	require Bio::KBase::AmethstService::AmethstServiceImpl;
	
	
	# slurp
	my $commands_list_data = read_file( $h->{'commands'});
	
	if (defined $shocktoken) {
		print "use shocktoken\n";
	} else {
		print "no shocktoken\n";
	}
	my $amethst_obj = new Bio::KBase::AmethstService::AmethstServiceImpl('shocktoken' => $shocktoken);
	
	
	
	
	
	my $local_data_files = {};
	
	
	# extract filenames
	open (CMD_SOURCE, '<', $h->{'commands'}) or die $!;
	while (my $line = <CMD_SOURCE>) {
		
		if ($line =~ /^\#job/) {
			my ($analysis) = $line =~ /^\#job\s*(\S+)/;
			
			unless (defined($analysis)) {
				die "analysis filename (after keyword job) not defined";
			}
			#my $analysis_filename = $analysis.'.RESULTS.tar.gz';
			
			#if (-e $analysis_filename) {
			#	die "analysis results file \"$analysis_filename\" already exists";
			#}
			
			my $cmd1 = <CMD_SOURCE>;
			my $cmd2 = <CMD_SOURCE>;
			my $sum_cmd = <CMD_SOURCE>;
			chomp($cmd1);
			chomp($cmd2);
			chomp($sum_cmd);
			foreach my $cmd (($cmd1, $cmd2, $sum_cmd)) {
				#print "parse: $cmd\n";
				foreach my $key (('--data_file', '--groups_list', '--tree')) {
					my @files = $cmd =~ /$key\s+(\S+)/g;
					#print "for key $key I found ".@files." files :".join(',',@files)."\n";
					
					foreach my $file (@files) {
						
						if ($file ne basename($file)) {
							die "error: only files in current directory are allowed";
						}
						
						unless (defined $local_data_files->{$file}) {
							unless (-e $file) {
								die "error: file \"$file\" not found";
							}
							$local_data_files->{$file} = 1;
						}
					} # end if
				} # end foreach
			} # end foreach
			
			
		} # end if
		
		
	} # end while
	close(CMD_SOURCE);

	print "files to upload: ".join(',', keys(%$local_data_files))."\n";
	if (defined $h->{'nosubmit'}) {
		exit(0);
	}

	unless (defined($shockurl) && $shockurl ne '') {
		$shockurl = read_shock_url();
		print "using deploy.cfg shock-server: $shockurl\n";
	} else {
		print "using env SHOCK_SERVER_URL: $shockurl\n";
	}



	my $shock = new SHOCK::Client($shockurl, $shocktoken);
	unless (defined $shock) {
		die;
	}

	# define input
	my $job_input = {};
	foreach my $file (keys(%$local_data_files)) {
		$job_input->{$file}->{'file'} = $file;
	}

	# upload input to SHOCK
	$shock->upload_temporary_files($job_input);

	# collect SHOCK nodes
	my $file2shock={};
	foreach my $file (keys(%$local_data_files)) {
		print "found file: $file\n";
		my $node = $job_input->{$file}->{'node'} || die "node not defined $file ";
		print "found node: $node\n";
		$file2shock->{$file} = $node;
	}

	$job_id = $amethst_obj->amethst($commands_list_data, $file2shock);
	
	unless (defined $job_id) {
		$job_id = 'undefined';
	}
	print "job submitted, job_id: $job_id\n";
	
	
	
} elsif (defined $h->{'status'}) {
	
	require Bio::KBase::AmethstService::AmethstServiceImpl;
	
	my $amethst_obj = new Bio::KBase::AmethstService::AmethstServiceImpl('shocktoken' => $shocktoken);
	my $status = $amethst_obj->status($h->{'status'}) || 'undefined';

	print "status: ".$status."\n";
	
	
} elsif (defined $h->{'download'}) {
	
	require Bio::KBase::AmethstService::AmethstServiceImpl;
	
	my $amethst_obj = new Bio::KBase::AmethstService::AmethstServiceImpl('shocktoken' => $shocktoken);
	my $results = $amethst_obj->results($h->{'download'}) || 'undefined';
	
	print "results: ".Dumper($results)."\n";
	
	foreach my $node (keys(%$results)) {
		my $file = $results->{$node};
		if (-e $file) {
			print "error: file $file already exists\n";
			exit(1);
		}
	}
	
	
	
	unless (defined($shockurl) && $shockurl ne '') {
		$shockurl = read_shock_url();
	}
	
	
	
	my $shock = new SHOCK::Client($shockurl, $shocktoken); # shock production
	unless (defined $shock) {
		die;
	}
	
	foreach my $node (keys(%$results)) {
		my $file = $results->{$node};
		
		print "downloading \"$file\" ...\n";
		$shock->download_to_path2($node, './'.$file);
		
	}
	print "all files downloaded\n";
	
} elsif (defined $h->{'delete'}) {

	require Bio::KBase::AmethstService::AmethstServiceImpl;
	
	my $amethst_obj = new Bio::KBase::AmethstService::AmethstServiceImpl('shocktoken' => $shocktoken);

	my $delete_status = $amethst_obj->delete_job($h->{'delete'}) || 'undefined';
	
	print "delete_status: $delete_status\n"
	
}
#unless (defined($h->{'nowait'})) {
#	AWE::Job::wait_and_download_job_results ('awe' => $awe, 'shock' => $shock, 'jobs' => [$job_id], 'clientgroup' => $clientgroup);
#}




