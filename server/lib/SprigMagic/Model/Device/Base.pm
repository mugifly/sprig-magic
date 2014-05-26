# SprigMagic - Device base class
package SprigMagic::Model::Device::Base;
use warnings;
use strict;
use utf8;

use Mojo::JSON;

# Constructor
sub new {
	my ($class, %hash) = @_;
	my $s = bless({}, $class);

	$s->{device_id} = $hash{device_id};
	$s->{device_name} = $hash{device_name};
	$s->{db_methods} = $hash{db_methods} || undef; # Optional
	$s->{connect_port} = $hash{connect_port} || undef; # Optional
	
	return $s;
}

# Device information ##########

# Return the category of the device
sub get_category_name {
	die; # Because it is the base module
	return 'foo'; # e.g., tv, aircon, ...
}

# Return the connect type of the device
sub get_connect_type {
	return 'serial';
}

# Queue processing ##########

# Process the command of a queue
sub process_queue_command {
	my ($s, $command) = @_;
	die; # Because it is the base module

	if ($command eq 'update') { # When received the "update" command, each module is needed updating the operating status
		# Update the operating status (e.g.)
		my $json_data = {
			power => $s->get_power(),
		};
		$s->update_operating_status($json_data);
	}

	return 1; # If processing was successful, this method must be returned 1 (true).
}

# Request to insert the command into queues
sub request_command_into_queue {
	my ($s, $command) = @_;
	if (!defined $s->{db_methods}) {
		die('The request_command_into_queue method is unavailable, because the db_methods field is not given.');
	}
	$s->{db_methods}->{queue_inserter}->($command);
}

# The data-store and operating status ##########

# Get the the operating status of the device
sub get_latest_operating_status {
	my ($s) = @_;
	my $operating_status = $s->get_temporary_kvs('OPERATING_STATUS');
	if (!defined $operating_status) {
		return undef;
	}
	return Mojo::JSON::decode_json($operating_status);
}

# Get the update of the operating status of the device (as epoch-sec)
sub get_operating_status_updated_at {
	my ($s) = @_;
	return $s->get_temporary_kvs('OPERATING_STATUS_UPDATED_AT') + 0; # to integer
}

# Update the operating status of the device (Its will be stored on temporary-kvs)
sub update_operating_status {
	my ($s, $json_obj) = @_;
	$s->set_temporary_kvs('OPERATING_STATUS', Mojo::JSON::encode_json($json_obj));
}

# Update the persistence data of the device on the database
sub set_persistence_data {
	my ($s, $json_obj) = @_;
	if (!defined $s->{db_methods}) {
		die('The db_persistence_data_update method is unavailable, because the db_methods field is not given.');
	}
	$s->{db_methods}->{persistence_data_updater}->(Mojo::JSON::encode_json($json_obj));
}

# Get a value from the temporary-kvs (It means volatility)
sub get_temporary_kvs {
	my ($s, $key) = @_;
	if (!defined $s->{db_methods}) {
		die('The get_tmpkvs method is unavailable, because the db_methods field is not given.');
	}
	$s->{db_methods}->{tmpkvs_getter}->($key);
}

# Set a value into the temporary-kvs (It means volatility)
sub set_temporary_kvs {
	my ($s, $key, $value) = @_;
	if (!defined $s->{db_methods}) {
		die('The set_tmpkvs method is unavailable, because the db_methods field is not given.');
	}
	$s->{db_methods}->{tmpkvs_setter}->($key, $value);
}

1;