package AMETHSTAWE;

use strict;
use warnings;

use AWE::Client;
use AWE::Job;
use SHOCK::Client;


use File::Slurp;
use JSON;
use File::Basename;

use Data::Dumper;



my $aweserverurl =  $ENV{'AWE_SERVER_URL'} || die "AWE_SERVER_URL not defined";
my $shockurl =  $ENV{'SHOCK_SERVER_URL'} || die "SHOCK_SERVER_URL not defined";
my $clientgroup = $ENV{'AWE_CLIENT_GROUP'} || die "AWE_CLIENT_GROUP not defined";

my $shocktoken=$ENV{'GLOBUSONLINE'} || $ENV{'KB_AUTH_TOKEN'} || die "KB_AUTH_TOKEN not defined";


my $task_tmpls_json = <<EOF;
{
	"amethst" : {
		"cmd" : "mg-amethst --local -f @[CMDFILE] -z [OUTPUT]",
		"inputs" : ["[CMDFILE]", "[ABUNDANCE-MATRIX]", "[GROUPS-LIST]"],
		"outputs" : ["[OUTPUT]"]
	},
	"amethst-tree" : {
		"cmd" : "mg-amethst --local -f @[CMDFILE] -z [OUTPUT]",
		"inputs" : ["[CMDFILE]", "[ABUNDANCE-MATRIX]", "[GROUPS-LIST]", "[TREE]"],
		"outputs" : ["[OUTPUT]"]
	}
}
EOF




# this is string-only version
sub amethst {
	my ($abundance_matrix, $groups_list, $commands_list, $tree) = @_;
	
	print STDERR "this is sub amethst \n";
	system("echo huhu > /home/ubuntu/test.log");
	
	return amethst_main(\$abundance_matrix, \$groups_list, \$commands_list, \$tree);
}


# scalars argument are treated as filenames, references to scalars as data in memory
sub amethst_main {
	my ($abundance_matrix, $groups_list, $commands_list, $tree) = @_;
	
	
	if (defined $tree && $tree eq '') {
		$tree = undef;
	}
	
	unless (defined $abundance_matrix) {
		die "abundance_matrix not defined";
	}
	
	unless (defined $groups_list) {
		die "groups_list not defined";
	}
	unless (defined $commands_list) {
		die "commands_list not defined";
	}
	
	#my $command_list_source
	#if (ref($commands_list) eq 'SCALAR' ) {
		# ref to scalar; data in memory
		
	#} elsif (ref($commands_list) eq '' ) {
		# filename; memor in file
	#}
	
	#open(MEMORY, '>', \$var)
    #or die "Can't open memory file: $!\n";
	#print MEMORY "foo!\n";
	
	
	my $tasks_array=[];
	
	open (CMD_SOURCE, '<', $commands_list) or die $!;
	while (my $line = <CMD_SOURCE>) {
		
		if ($line =~ /^\#job/) {
			my ($analysis) = $line =~ /^\#job\s*(\S+)/;
			
			unless (defined($analysis)) {
				die "analysis filename (after keyword job) not defined";
			}
			my $analysis_filename = $analysis.'.RESULTS.tar.gz';
			
			if (-e $analysis_filename) {
				die "analysis results file \"$analysis_filename\" already exists";
			}
			
			my $cmd1 = <CMD_SOURCE>;
			my $cmd2 = <CMD_SOURCE>;
			my $sum_cmd = <CMD_SOURCE>;
			chomp($cmd1);
			chomp($cmd2);
			chomp($sum_cmd);
			
			my $pair_file = $line.$cmd1."\n".$cmd2."\n".$sum_cmd;
			
			#print $cmd1."\n";
			#print $cmd2."\n";
			#print $sum_cmd."\n";
			
			my @input_files = process_pair($cmd1, $cmd2, $sum_cmd);
			push(@{$tasks_array}, [$analysis_filename, $pair_file, @input_files]);
		
		}
	
	}


	close(CMD_SOURCE);

	my $am_data;
	if (ref($abundance_matrix) eq 'SCALAR' ) {
		$am_data = $$abundance_matrix; # dereference data
	} elsif (ref($abundance_matrix) eq ''){
		$am_data = read_file( $abundance_matrix) ; # read data from file
	}

	my $grp_data;
	if (ref($groups_list) eq 'SCALAR' ) {
		$grp_data = $$groups_list;  # dereference data
	} elsif (ref($groups_list) eq ''){
		$grp_data = read_file( $groups_list );# read data from file
	}

	my $tree_data;
	if (defined $tree) {
		if (ref($tree) eq 'SCALAR' ) {
			$tree_data = $$tree;  # dereference data
		} elsif (ref($tree) eq ''){
			$tree_data = read_file( $tree );# read data from file
		}
	}

	return create_and_submit_workflow($tasks_array, $am_data, $grp_data, $tree_data);


}

sub process_pair {
	my ($cmd1, $cmd2, $sum_cmd) = @_;
	
	
	my ($matrix_file) = $cmd1 =~ /-f\s+(\S+)/;
	unless (defined $matrix_file) {
		die;
	}
	print "matrix_file: $matrix_file\n";
	
	my ($group_file) = $cmd1 =~ /-g\s+(\S+)/;
	unless (defined $group_file) {
		die;
	}
	print "group_file: $group_file\n";
	
	my ($tree_file) = $cmd1 =~ /-a\s+(\S+)/;
	if (defined $tree_file) {
		print "tree_file: $tree_file\n";
	}
	
	
	if (-e $matrix_file) {
		print "found $matrix_file\n";
	} else {
		die "$matrix_file not found"
	}
	
	if (-e $group_file) {
		print "found $group_file\n";
	} else {
		die "$group_file not found"
	}
	
	if (defined $tree_file) {
		
		if (-e $tree_file) {
			print "found $tree_file\n";
		} else {
			die "$tree_file not found"
		}
	}
	
	return ($matrix_file, $group_file, $tree_file);
}




sub create_and_submit_workflow {

	my ($tasks_array, $abundance_matrix, $groups_list, $tree) = @_;
	
	if (@$tasks_array == 0) {
		die "error: tasks_array empty";
	}
	
	
	############################################
	# connect to AWE server and check the clients

	my $awe = new AWE::Client($aweserverurl, $shocktoken);
	unless (defined $awe) {
		die;
	}

	$awe->checkClientGroup($clientgroup)==0 || die;


	############################################
	#connect to SHOCK server

	print "connect to SHOCK\n";
	my $shock = new SHOCK::Client($shockurl, $shocktoken); # shock production
	unless (defined $shock) {
		die;
	}



	my $task_tmpls;



	$task_tmpls = decode_json($task_tmpls_json);

	
	my $amethst_version = 'amethst';
	if (defined($tree)) {
		$amethst_version = 'amethst-tree';
	}


	my $tasks = [];
	my $job_input = {};

	$job_input->{'ABUNDANCE-MATRIX'}->{'data'} = $abundance_matrix;
	$job_input->{'GROUPS-LIST'}->{'data'} = $groups_list;
	if (defined($tree)) {
		$job_input->{'TREE'}->{'data'} = $tree;
	}
	
	# create and sumbit workflows
	for (my $i = 0 ; $i < @$tasks_array ; ++$i) {
		my $task_array = $tasks_array->[$i];
		
		my ($analysis_filename, $pair_file, $matrix_file, $group_file, $tree_file) = @{$task_array};
		
		
		my $input_filename = 'command_'.$i.'.txt';
		
		print "got:\n $pair_file\n $matrix_file, $group_file, $tree_file\n";
		
		
		my $new_task = {
			"task_id" => "amethst_".$i,
			"task_template" => $amethst_version,
			"CMDFILE" => ["shock", "[CMDFILE_$i]", $input_filename],
			"ABUNDANCE-MATRIX" => ["shock", "[ABUNDANCE-MATRIX]", $matrix_file],
			"GROUPS-LIST" => ["shock", "[GROUPS-LIST]", $group_file],
			"OUTPUT" => $analysis_filename
		};
		if ( defined($tree) ) {
			$new_task->{'TREE'} = ["shock", "[TREE]", $tree_file];
		}
		
		push (@{$tasks}, $new_task );
		
		
		
		
		$job_input->{'CMDFILE_'.$i}->{'data'} = $pair_file;
		
		
	}





	my $awe_job = AWE::Job->new(
	'info' => {
		"pipeline"=> "amethst",
		"name"=> "amethst-job_".int(rand(100000)),
		"project"=> "project",
		"user"=> "wgerlach",
		"clientgroups"=> $clientgroup,
		"noretry"=> JSON::true
	},
	'shockhost' => $shockurl,
	'task_templates' => $task_tmpls,
	'tasks' => $tasks
	);

	my $json = JSON->new;
	print "AWE job without input:\n".$json->pretty->encode( $awe_job->hash() )."\n";




	$shocktoken || die "no shocktoken defined";
	if ($shocktoken eq '') {
		die "no shocktoken defined";
	}
	#upload job input files
	#print "job_input: ". Dumper(keys(%$job_input))."\n";
	$shock->upload_temporary_files($job_input);


	# create job with the input defined above
	my $workflow = $awe_job->create(%$job_input);#define workflow output

	print "AWE job ready for submission:\n";
	print $json->pretty->encode( $workflow )."\n";

	#exit(0);
	print "submit job to AWE server...\n";
	my $submission_result = $awe->submit_job('json_data' => $json->encode($workflow));

	my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";


	print "result from AWE server:\n".$json->pretty->encode( $submission_result )."\n";
	return $job_id;
}

sub status {
	my ($job_id) = @_;
	
	my $awe = new AWE::Client($aweserverurl, $shocktoken);
	unless (defined $awe) {
		die;
	}
	
	my $job = $awe->showJob($job_id);
	print Dumper($job)."\n";
	
	return $job->{'data'}->{'state'};
	
}

sub results {
	my ($job_id) = @_;
	
	my $awe = new AWE::Client($aweserverurl, $shocktoken);
	unless (defined $awe) {
		die;
	}
	
	
	
	my $job = $awe->showJob($job_id);
	print Dumper($job)."\n";
	
	unless (defined $job->{'data'}) {
		die "job->{'data'} undef";
	}
	
	unless (defined $job->{'data'}->{'tasks'}) {
		die "job->{'data'}->{'tasks'} undef";
	}
	
	
	if (@{$job->{'data'}->{'tasks'}} ==0 ) {
		die "job->{'data'}->{'tasks'} == 0";
	}
	
	print "count tasks: ".@{$job->{'data'}->{'tasks'}}."\n";
	
	my $output_nodes = AWE::Job::get_awe_output_nodes($job->{'data'}, 'only_last_task' => 0);
	print Dumper($output_nodes)."\n";
	
	#return shocknode-filename pairs
	my $node_mapping={};
	foreach my $file (keys(%$output_nodes)) {
		my $node = $output_nodes->{$file}->{'node'};
		$node_mapping->{$node}=$file;
	}
	
	
	return $node_mapping;
	
}

# this will delete shock nodes only when they have the "temporary" attribute
sub delete_job {
	my ($job_id) = @_;
	
	my $awe = new AWE::Client($aweserverurl, $shocktoken);
	unless (defined $awe) {
		die;
	}
	
	my $shock = new SHOCK::Client($shockurl, $shocktoken); # shock production
	unless (defined $shock) {
		die;
	}

	
	my $job_deleted = AWE::Job::delete_jobs('awe' => $awe, 'shock' => $shock , 'jobs'=> [$job_id]);
	
	print "job_deleted: $job_deleted\n";
	
	if ($job_deleted == 1) {
		
		return "success";
	}
	return "not deleted";
	
}
