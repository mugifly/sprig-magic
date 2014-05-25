package SprigMagic::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
use utf8;

use Time::Piece;

sub top {
	my $s = shift;
	$s->redirect_to('/admin/users');
}

sub users {
	my $s = shift;

	if (defined $s->param('action')) {
		# Modified of the user
		my $action = $s->param('action');
		my $user_id = $s->param('user_id');
		if ($user_id eq $s->userId()) {
			$s->flash('message_error', 'You can not change your self.');
		} else {
			if ($action eq 'status' && defined $s->param('status')) {
				# Change the status
				my $status = $s->param('status');
				$status =~ s/^([^0-9]+)$//;
				my $sth = $s->db->prepare('UPDATE user SET status = ? WHERE id = ?;');
				$sth->execute($status, $user_id);
				$sth->finish();
			} elsif ($action eq 'delete') {
				# Delete the account
				my $sth = $s->db->prepare('DELETE FROM user WHERE id = ?;');
				$sth->execute($user_id);
				$sth = $s->db->prepare('DELETE FROM session WHERE user_id = ?;');
				$sth->execute($user_id);
				$sth->finish();
			}
		}
		$s->redirect_to('/admin/users');
		return;
	}

	# List of users

	# Find users
	my @users = ();
	my $sth = $s->db->prepare('SELECT * FROM user;');
	$sth->execute();
	while (my $user = $sth->fetchrow_hashref) {
		$user->{last_logged_in_date} = Time::Piece->strptime($user->{last_logged_in_at}, '%s')->strftime('%Y/%m/%d %H:%M %z');

		push(@users, $user);
	}
	$sth->finish();

	# Render
	$s->render(
		users => \@users
	);
}

sub devices {
	my $s = shift;

	# Load the device helper
	$s->app->plugin('SprigMagic::Helper::Device');
	
	if (defined $s->param('action')) {
		# Modified of the device
		my $action = $s->param('action');
		if ($action eq 'add') {
			# Add the device
			my $name = $s->param('device_name');
			my $port = $s->param('connect_port');
			my $module_name = $s->param('module_name');
			my $status = 1; # Normal
			if (defined $name && defined $port && defined $module_name) { # If valid
				# Generate the device module
				eval {
					# Generate the device module
					my $module = $s->get_device_module($module_name, undef, $name, $port); # Get the device module with using helper
					# Get the category name from the module
					my $category = $module->get_category();
					
					my $sth = $s->db->prepare('INSERT INTO device VALUES(?, ?, ?, ?, ?, ?, ?);');
					$sth->execute(undef, $name, $status, $category, $module_name, $port, undef);
					$s->redirect_to('/admin/devices');
					return;
				}; if ($@) {
					$s->stash('message_error', $@);	
				}
			} else {
				$s->stash('message_error', 'The parameter is invalid.');
			}

		} elsif ($action eq 'delete') {
			# Delete the device
			my $device_id = $s->param('device_id');
			my $sth = $s->db->prepare('DELETE FROM device WHERE id = ?;');
			$sth->execute($device_id);
			$s->redirect_to('/admin/devices');
			return;

		} elsif ($action eq 'status') {
			# Change the status of the device
			my $device_id = $s->param('device_id');
			my $status = $s->param('status');
			$status =~ s/[^0-9]//;
			if (defined $device_id && defined $status) {
				my $sth = $s->db->prepare('UPDATE device SET status = ? WHERE id = ?;');
				$sth->execute($status, $device_id);
				$s->redirect_to('/admin/devices');
				return;
			} else {
				$s->stash('message_error', 'The device-id or status is invalid.');
			}

		}
	}

	# List of devices

	# Find devices
	my @devices = ();
	my $sth = $s->db->prepare('SELECT * FROM device;');
	$sth->execute();
	while (my $d = $sth->fetchrow_hashref) {
		# Generate the device module
		eval{
			my $module = $s->get_device_module($d->{module_name}, $d->{id}, $d->{name}, $d->{connect_port}); # Get the device module with using helper
			$d->{module} = $module;
		};
		
		push(@devices, $d);
	}
	$sth->finish();

	# Listup names of the device module
	my @device_module_names = $s->get_device_module_names();

	# Render
	$s->render(
		devices => \@devices,
		device_module_names => \@device_module_names,
		form_device_name => $s->param('device_name') || '',
		form_connect_port => $s->param('connect_port') || '',
		form_module_name => $s->param('module_name') || '',
	);
}

1;
