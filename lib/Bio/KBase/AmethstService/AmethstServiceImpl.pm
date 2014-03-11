package Bio::KBase::AmethstService::AmethstServiceImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME
 
 AMETHSTService
 
 =head1 DESCRIPTION
 
 
 
 =cut

#BEGIN_HEADER
use AMETHSTAWE;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    #END_CONSTRUCTOR
	
    if ($self->can('_init_instance'))
    {
		$self->_init_instance();
    }
    return $self;
}

=head1 METHODS
 
 
 
 =head2 amethst
 
 $job_id = $obj->amethst($abundance_matrix, $groups_list, $commands_list, $tree)
 
 =over 4
 
 =item Parameter and return types
 
 =begin html
 
 <pre>
 $abundance_matrix is a string
 $groups_list is a string
 $commands_list is a string
 $tree is a string
 $job_id is a string
 
 </pre>
 
 =end html
 
 =begin text
 
 $abundance_matrix is a string
 $groups_list is a string
 $commands_list is a string
 $tree is a string
 $job_id is a string
 
 
 =end text
 
 
 
 =item Description
 
 last parameter "tree" is optional
 
 =back
 
 =cut

sub amethst
{
    my $self = shift;
    my($abundance_matrix, $groups_list, $commands_list, $tree) = @_;
	
    my @_bad_arguments;
    (!ref($abundance_matrix)) or push(@_bad_arguments, "Invalid type for argument \"abundance_matrix\" (value was \"$abundance_matrix\")");
    (!ref($groups_list)) or push(@_bad_arguments, "Invalid type for argument \"groups_list\" (value was \"$groups_list\")");
    (!ref($commands_list)) or push(@_bad_arguments, "Invalid type for argument \"commands_list\" (value was \"$commands_list\")");
    (!ref($tree)) or push(@_bad_arguments, "Invalid type for argument \"tree\" (value was \"$tree\")");
    if (@_bad_arguments) {
		my $msg = "Invalid arguments passed to amethst:\n" . join("", map { "\t$_\n" } @_bad_arguments);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'amethst');
    }
	
    my $ctx = $Bio::KBase::AmethstService::Service::CallContext;
    my($job_id);
    #BEGIN amethst
	$job_id = AMETHSTAWE::amethst($abundance_matrix, $groups_list, $commands_list, $tree);
    #END amethst
    my @_bad_returns;
    (!ref($job_id)) or push(@_bad_returns, "Invalid type for return variable \"job_id\" (value was \"$job_id\")");
    if (@_bad_returns) {
		my $msg = "Invalid returns passed to amethst:\n" . join("", map { "\t$_\n" } @_bad_returns);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'amethst');
    }
    return($job_id);
}




=head2 status
 
 $status = $obj->status($job_id)
 
 =over 4
 
 =item Parameter and return types
 
 =begin html
 
 <pre>
 $job_id is a string
 $status is a string
 
 </pre>
 
 =end html
 
 =begin text
 
 $job_id is a string
 $status is a string
 
 
 =end text
 
 
 
 =item Description
 
 
 
 =back
 
 =cut

sub status
{
    my $self = shift;
    my($job_id) = @_;
	
    my @_bad_arguments;
    (!ref($job_id)) or push(@_bad_arguments, "Invalid type for argument \"job_id\" (value was \"$job_id\")");
    if (@_bad_arguments) {
		my $msg = "Invalid arguments passed to status:\n" . join("", map { "\t$_\n" } @_bad_arguments);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'status');
    }
	
    my $ctx = $Bio::KBase::AmethstService::Service::CallContext;
    my($status);
    #BEGIN status
		$status = AMETHSTAWE::status($job_id);
    #END status
    my @_bad_returns;
    (!ref($status)) or push(@_bad_returns, "Invalid type for return variable \"status\" (value was \"$status\")");
    if (@_bad_returns) {
		my $msg = "Invalid returns passed to status:\n" . join("", map { "\t$_\n" } @_bad_returns);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'status');
    }
    return($status);
}




=head2 results
 
 $return = $obj->results($job_id)
 
 =over 4
 
 =item Parameter and return types
 
 =begin html
 
 <pre>
 $job_id is a string
 $return is a reference to a hash where the key is a string and the value is a string
 
 </pre>
 
 =end html
 
 =begin text
 
 $job_id is a string
 $return is a reference to a hash where the key is a string and the value is a string
 
 
 =end text
 
 
 
 =item Description
 
 
 
 =back
 
 =cut

sub results
{
    my $self = shift;
    my($job_id) = @_;
	
    my @_bad_arguments;
    (!ref($job_id)) or push(@_bad_arguments, "Invalid type for argument \"job_id\" (value was \"$job_id\")");
    if (@_bad_arguments) {
		my $msg = "Invalid arguments passed to results:\n" . join("", map { "\t$_\n" } @_bad_arguments);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'results');
    }
	
    my $ctx = $Bio::KBase::AmethstService::Service::CallContext;
    my($return);
    #BEGIN results
		$return = AMETHSTAWE::results($job_id);
    #END results
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
		my $msg = "Invalid returns passed to results:\n" . join("", map { "\t$_\n" } @_bad_returns);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'results');
    }
    return($return);
}




=head2 delete_job
 
 $results = $obj->delete_job($job_id)
 
 =over 4
 
 =item Parameter and return types
 
 =begin html
 
 <pre>
 $job_id is a string
 $results is a string
 
 </pre>
 
 =end html
 
 =begin text
 
 $job_id is a string
 $results is a string
 
 
 =end text
 
 
 
 =item Description
 
 
 
 =back
 
 =cut

sub delete_job
{
    my $self = shift;
    my($job_id) = @_;
	
    my @_bad_arguments;
    (!ref($job_id)) or push(@_bad_arguments, "Invalid type for argument \"job_id\" (value was \"$job_id\")");
    if (@_bad_arguments) {
		my $msg = "Invalid arguments passed to delete_job:\n" . join("", map { "\t$_\n" } @_bad_arguments);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'delete_job');
    }
	
    my $ctx = $Bio::KBase::AmethstService::Service::CallContext;
    my($results);
    #BEGIN delete_job
	$results = AMETHSTAWE::delete_job($job_id);
    #END delete_job
    my @_bad_returns;
    (!ref($results)) or push(@_bad_returns, "Invalid type for return variable \"results\" (value was \"$results\")");
    if (@_bad_returns) {
		my $msg = "Invalid returns passed to delete_job:\n" . join("", map { "\t$_\n" } @_bad_returns);
		Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
		method_name => 'delete_job');
    }
    return($results);
}




=head2 version
 
 $return = $obj->version()
 
 =over 4
 
 =item Parameter and return types
 
 =begin html
 
 <pre>
 $return is a string
 </pre>
 
 =end html
 
 =begin text
 
 $return is a string
 
 =end text
 
 =item Description
 
 Return the module version. This is a Semantic Versioning number.
 
 =back
 
 =cut

sub version {
    return $VERSION;
}

=head1 TYPES
 
 
 
 =cut

1;
