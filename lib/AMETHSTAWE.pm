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


our $VERSION = '1.0.0';

# new AMETHSTAWE('shocktoken' => <token>)
sub new {
    my ($class, %h) = @_;
    
	if (defined($h{'shocktoken'}) && $h{'shocktoken'} eq '') {
		$h{'shocktoken'} = undef;
	}
	
    my $self = {
		aweserverurl	=> $ENV{'AWE_SERVER_URL'} ,
		shockurl		=> $ENV{'SHOCK_SERVER_URL'},
		clientgroup		=> $ENV{'AWE_CLIENT_GROUP'},
		shocktoken		=> $h{'shocktoken'}
	};
	
	
	
	
    bless $self, $class;
    
	$self->readConfig();
	
	
	return $self;
}


sub aweserverurl {
    my ($self) = @_;
    return $self->{'aweserverurl'};
}
sub shockurl {
    my ($self) = @_;
    return $self->{'shockurl'};
}
sub clientgroup {
    my ($self) = @_;
    return $self->{'clientgroup'};
}
sub shocktoken {
    my ($self, $value) = @_;
	
	if (defined $value) {
		$self->{'shocktoken'} = $value;
	}
	
    return $self->{'shocktoken'};
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
		$self->{'aweserverurl'} = $cfg->{'awe-server'};
		
		unless (defined($self->{'aweserverurl'}) && $self->{'aweserverurl'} ne "") {
			die "awe-server not found in config";
		}
	}
	
	
	unless (defined $self->{'shockurl'} && $self->{'shockurl'} ne '') {
		$self->{'shockurl'} =  $cfg->{'shock-server'};
		
		unless (defined(defined $self->{'shockurl'}) && $self->{'shockurl'} ne "") {
			die "shock-server not found in config";
		}
	}
	
	unless (defined $self->{'clientgroup'} && $self->{'clientgroup'} ne '') {
		$self->{'clientgroup'} =  $cfg->{'clientgroup'};
		
		unless (defined($self->{'clientgroup'}) && $self->{'clientgroup'} ne "") {
			die "clientgroup not found in config";
		}
	}
}


# scalars argument are treated as filenames, references to scalars are treated as data in memory
sub amethst {
	my ($self, $commands_list, $file2shock) = @_;
	
	$self->shockurl || die "error(amethst): shockurl not defined";

		
	my $output_zip;
	
	my $tasks_array=[];
	
	#commands file is split into smaller pieces
	open (CMD_SOURCE, '<', $commands_list) or die $!;
	while (my $line = <CMD_SOURCE>) {
		
		if ($line =~ /^\#output\_zip/) {
			($output_zip) = $line =~ /^\#output\_zip\=(\S+)/;
		}
		
		
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
			
			my $used_files = $self->process_pair($file2shock, $cmd1, $cmd2, $sum_cmd);
			push(@{$tasks_array}, [$analysis_filename, $pair_file, $used_files]);
		
		}
	
	}


	close(CMD_SOURCE);

	return $self->create_and_submit_workflow($output_zip, $tasks_array);


}


# parse filenames form commands_file
sub process_pair {
	my ($self, $file2shock, $cmd1, $cmd2, $sum_cmd) = @_;
	
	
	my $used_files = {};
	foreach my $cmd (($cmd1, $cmd2, $sum_cmd)) {
		foreach my $key (('--data_file', '--groups_list', '--tree')) {
			my @files = $cmd =~ /$key\s+(\S+)/g;
			foreach my $file (@files) {
				
				print "found file: $file\n";
				my $node = $file2shock->{$file} || die "file $file not in file2shock hash";
				print "found node: $node\n";
				$used_files->{$file} = $node;
			} # end if
		} # end foreach
	} # end foreach
	
	
			
		
	return $used_files;
}




sub create_and_submit_workflow {
	my ($self, $output_zip, $tasks_array) = @_;
	
	if (@$tasks_array == 0) {
		die "error: tasks_array empty";
	}
	
	
	#$self->shocktoken || die "no shocktoken defined"; # required for upload
	#if ($self->shocktoken eq '') {
	#	die "no shocktoken defined";
	#}
	
	$self->shockurl || die "error: shockurl not defined";
	
	
	############################################
	# connect to AWE server and check the clients

	my $awe = new AWE::Client($self->aweserverurl, $self->shocktoken);
	unless (defined $awe) {
		die;
	}

	$awe->checkClientGroup($self->clientgroup)==0 || die "no clients in clientgroup found, ".$self->clientgroup." (AWE server: ".$self->aweserverurl.")";


	
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
		
		my ($analysis_filename, $pair_file, $used_files) = @{$task_array};
		
		
		my $input_filename = 'command_'.$i.'.txt';
		
		#create and add a new task
		my $newtask = $workflow->addTask(new AWE::Task());
		
		$newtask->command('AMETHST.pl -f @'.$input_filename.' -z --all_name '.$analysis_filename);
		
		
		
				
		# define and add input nodes to the task
		foreach my $filename (keys(%$used_files)) {
			my $node = $used_files->{$filename};
			$newtask->addInput(new AWE::TaskInput('node' => $node,	'host' => $self->shockurl, 'filename' => $filename));
		}
		$newtask->addInput(new AWE::TaskInput('data' => \$pair_file, 'filename' => $input_filename));

		
		# define and add output nodes to the task; return value is a reference that can be used to create an input node for the next task
		my $output_reference = $newtask->addOutput(new AWE::TaskOutput($analysis_filename, $self->shockurl));
		push (@summary_inputs, new AWE::TaskInput('reference' => $output_reference));
		
		
	}

	
	# create and add last summary task
	my $newtask = $workflow->addTask(new AWE::Task());
	
	unless (defined $output_zip) {
		$output_zip = 'AMETHST_Summary.tar.gz';
	}
	#old:'compile_p-values-summary_files.pl --output_zip='.$output_zip
	$newtask->command('AMETHST.pl -c --summary_name='.$output_zip);
	$newtask->addInput(@summary_inputs); # these input nodes connect this task with the previous tasks
	
	# define output nodes for last task
	#my $prefix = 'my_compiled.P_VALUES_SUMMARY.';
	#my @output_suffixes = ('scaled_avg_dist', 'raw_avg_dist_stdev','raw_avg_dist','p_values','num_perm');
	#foreach my $suffix (@output_suffixes) {
	#	$newtask->addOutput(new AWE::TaskOutput($prefix.$suffix, $self->shockurl));
	#}
	
	
	$newtask->addOutput(new AWE::TaskOutput($output_zip, $self->shockurl));
	

	my $json = JSON->new;

	print "AWE job without input:\n".$json->pretty->encode( $workflow->getHash() )."\n";

	# upload splitted command files
	
	print STDERR "self->shockurl: ".$self->shockurl."\n";
	print STDERR "self->shocktoken: ".$self->shocktoken."\n";
	
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
	
	my $output_nodes = AWE::Job::get_awe_output_nodes($job->{'data'}, 'only_last_task' => 1);
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

