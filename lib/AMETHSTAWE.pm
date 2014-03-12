package AMETHSTAWE;

use strict;
use warnings;


use Config::Simple;
use File::Slurp;
use JSON;
use File::Basename;

use Data::Dumper;


use SHOCK::Client;

use AWE::Client;
use AWE::Job;

use AWE::Workflow;
use AWE::Task;
use AWE::TaskInput;
use AWE::TaskOutput;



1;

# new AMETHSTAWE('shocktoken' => <token>)
sub new {
    my ($class, %h) = @_;
    
	
    my $self = {
		aweserverurl	=> $ENV{'AWE_SERVER_URL'} ,
		shockurl		=> $ENV{'SHOCK_SERVER_URL'},
		clientgroup		=> $ENV{'AWE_CLIENT_GROUP'},
		shocktoken		=> $h{'shocktoken'} || $ENV{'GLOBUSONLINE'} || $ENV{'KB_AUTH_TOKEN'}
	};
	
	
	
	
    bless $self, $class;
    
	$self->readConfig();
	
	return $self;
}


sub aweserverurl {
    my ($self) = @_;
    return $self->{aweserverurl};
}
sub shockurl {
    my ($self) = @_;
    return $self->{shockurl};
}
sub clientgroup {
    my ($self) = @_;
    return $self->{clientgroup};
}
sub shocktoken {
    my ($self) = @_;
    return $self->{shocktoken};
}

sub readConfig {
	my ($self) = @_;
	
	my $conf_file = $ENV{'KB_TOP'}.'/deployment.cfg';
	unless (-e $conf_file) {
		die "error: deployment.cfg not found ($conf_file)";
	}
	
	
	my $cfg_full = Config::Simple->new($conf_file );
	my $cfg = $cfg_full->param(-block=>'AmethstService');
	
	unless (defined $self->{'aweserverurl'} && $self->{'aweserverurl'} ne '') {
		$self->{'aweserverurl'} =  $cfg->param('awe-server' );
		
		unless (defined($self->{'aweserverurl'}) && $self->{'aweserverurl'} ne "") {
			die "awe-server not found in config";
		}
	}
	
	unless (defined $self->{'shockurl'} && defined $self->{'shockurl'} ne '') {
		$self->{'shockurl'} =  $cfg->param('shock-server' );
		
		unless (defined(defined $self->{'shockurl'}) && defined $self->{'shockurl'} ne "") {
			die "shock-server not found in config";
		}
	}
	
	unless (defined $self->{'clientgroup'} && $self->{'clientgroup'} ne '') {
		$self->{'clientgroup'} =  $cfg->param('clientgroup');
		
		unless (defined($self->{'clientgroup'}) && $self->{'clientgroup'} ne "") {
			die "clientgroup not found in config";
		}
	}
}


# this is string-only version
sub amethst_string {
	my ($self, $abundance_matrix, $groups_list, $commands_list, $tree) = @_;
	
	print STDERR "this is sub amethst \n";
	system("echo huhu > /home/ubuntu/test.log");
	
	return $self->amethst(\$abundance_matrix, \$groups_list, \$commands_list, \$tree);
}


# scalars argument are treated as filenames, references to scalars are treated as data in memory
sub amethst {
	my ($self, $abundance_matrix, $groups_list, $commands_list, $tree) = @_;
	
	
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
	
		
	
	my $tasks_array=[];
	
	#commands file is split into smaller pieces
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

	return $self->create_and_submit_workflow($tasks_array, $am_data, $grp_data, $tree_data);


}

sub process_pair {
	my ($self, $cmd1, $cmd2, $sum_cmd) = @_;
	
	
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
	my ($self, $tasks_array, $abundance_matrix, $groups_list, $tree) = @_;
	
	if (@$tasks_array == 0) {
		die "error: tasks_array empty";
	}
	
	
	$self->shocktoken || die "no shocktoken defined"; # required for upload
	if ($self->shocktoken eq '') {
		die "no shocktoken defined";
	}
	
	
	
	############################################
	# connect to AWE server and check the clients

	my $awe = new AWE::Client($self->aweserverurl, $self->shocktoken);
	unless (defined $awe) {
		die;
	}

	$awe->checkClientGroup($self->clientgroup)==0 || die;


	
	# workflow document: parameters define go into the "info" section of the AWE Job
	my $workflow = new AWE::Workflow(
		"pipeline"=> "amethst",
		"name"=> "amethst",
		"project"=> "amethst",
		"user"=> "kbase-user",
		"clientgroups"=> $self->clientgroup,
		"noretry"=> JSON::true
	);
		
	
	
	
	
	my @summary_inputs=();
	
	
	for (my $i = 0 ; $i < @$tasks_array ; ++$i) {
		my $task_array = $tasks_array->[$i];
		
		my ($analysis_filename, $pair_file, $matrix_file, $group_file, $tree_file) = @{$task_array};
		
		
		my $input_filename = 'command_'.$i.'.txt';
		
		#create and add a new task
		my $newtask = $workflow->addTask(new AWE::Task());
		
		$newtask->command('mg-amethst -f @'.$input_filename.' -z '.$analysis_filename);
		
		
		
		print "got:\n $pair_file\n $matrix_file, $group_file\n";
		
		
		# define and add input nodes to the task
		$newtask->addInput(new AWE::TaskInput('data' => \$pair_file,		'filename' => $input_filename));
		$newtask->addInput(new AWE::TaskInput('data' => \$abundance_matrix, 'filename' => $matrix_file));
		$newtask->addInput(new AWE::TaskInput('data' => \$groups_list,		'filename' => $group_file));
		if (defined($tree)) {
			$newtask->addInput(new AWE::TaskInput('data' => \$tree, 'filename' => $tree_file));
		}
		
		# define and add output nodes to the task; return value is a reference that can be used to create an input node for the next task
		my $output_reference = $newtask->addOutput(new AWE::TaskOutput($analysis_filename, $self->shockurl));
		push (@summary_inputs, new AWE::TaskInput('reference' => $output_reference));
		
		
	}

	
	# create and add last summary task
	my $newtask = $workflow->addTask(new AWE::Task());
	
	$newtask->command('mg-amethst --summary');
	$newtask->addInput(@summary_inputs); # these input nodes connect this task with the previous tasks
	
	# define output nodes for last task
	my $prefix = 'my_compiled.P_VALUES_SUMMARY.';
	my @output_suffixes = ('scaled_avg_dist', 'raw_avg_dist_stdev','raw_avg_dist','p_values','num_perm');
	foreach my $suffix (@output_suffixes) {
		$newtask->addOutput(new AWE::TaskOutput($prefix.$suffix, $self->shockurl));
	}
	
	

	my $json = JSON->new;
	print "AWE job without input:\n".$json->pretty->encode( $workflow->getHash() )."\n";
	
	
	
	
	$workflow->shock_upload($self->shockurl, $self->shocktoken);
	
	print "AWE job with input:\n".$json->pretty->encode( $workflow->getHash() )."\n";




	print "submit job to AWE server...\n";
	my $submission_result = $awe->submit_job('json_data' => $json->encode($workflow->getHash()));

	my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";


	print "result from AWE server:\n".$json->pretty->encode( $submission_result )."\n";
	return $job_id;
	
}

sub status {
	my ($self, $job_id) = @_;
	
	my $awe = new AWE::Client($self->aweserverurl, $self->shocktoken);
	unless (defined $awe) {
		die;
	}
	
	my $job = $awe->showJob($job_id);
	print Dumper($job)."\n";
	
	return $job->{'data'}->{'state'};
	
}

sub results {
	my ($self, $job_id) = @_;
	
	my $awe = new AWE::Client($self->aweserverurl, $self->shocktoken);
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
	my ($self, $job_id) = @_;
	
	my $awe = new AWE::Client($self->aweserverurl, $self->shocktoken);
	unless (defined $awe) {
		die;
	}
	
	my $shock = new SHOCK::Client($self->shockurl, $self->shocktoken); # shock production
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

