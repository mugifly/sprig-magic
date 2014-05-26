package SprigMagic::Controller::Devices;
use Mojo::Base 'Mojolicious::Controller';

sub devices_list {
	my $s = shift;
	$s->render();
}

sub devices_list_api {
	my $s = shift;

	# Load the device helper
	$s->app->plugin('SprigMagic::Helper::Device');

	my %devices = ();

	# Get devices
	my $sth;
	if (defined $s->param('category')) {
		$sth = $s->db->prepare('SELECT * FROM device WHERE category_name = ?;');
		$sth->execute($s->param('category'));
	} else {
		$sth = $s->db->prepare('SELECT * FROM device;');
		$sth->execute();
	}
	
	while (my $d = $sth->fetchrow_hashref) {
		# Generate the device module
		my $module = $s->get_device_module($d->{module_name}, $d->{id}, $d->{name}, undef, $s->db(), $s->tmpdb());
		# Get the latest operating status
		$d->{operating_status} = $module->get_latest_operating_status();
		$d->{operating_status_updated_at} = $module->get_operating_status_updated_at();
		
		$devices{$d->{id}} = $d;
	}
	
	# Render
	$s->render(json => {
		devices => \%devices,
	});
}

sub device_detail {
	my $s = shift;

	$s->stash('device_id', $s->param('device_id'));
	$s->render();
}

sub device_detail_api {
	my $s = shift;
	my $device_id = $s->param('device_id');
	
	# Load the device helper
	$s->app->plugin('SprigMagic::Helper::Device');

	# Get a device
	my $sth = $s->db->prepare('SELECT * FROM device WHERE id = ?');
	$sth->execute($device_id);
	my $d = $sth->fetchrow_hashref;

	if (!defined $d) {
		$s->render(json => undef, status => 404);
		return;
	}

	# Generate the device module
	my $module = $s->get_device_module($d->{module_name}, $d->{id}, $d->{name}, undef, $s->db(), $s->tmpdb());
	# Get the latest operating status
	$d->{operating_status} = $module->get_latest_operating_status();
	$d->{operating_status_updated_at} = $module->get_operating_status_updated_at();
	
	# Render
	$s->render(json => {
		device => $d
	});
}

sub device_post {
	my $s = shift;
	my $device_id = $s->param('device_id');
	my $command = $s->param('command');

	# Check whether device is exists
	my $sth = $s->db->prepare('SELECT * FROM device WHERE id = ?;');
	$sth->execute($device_id);
	my $d = $sth->fetchrow_hashref;
	if (!defined $d || !defined $d->{id}) {
		$s->render(json => {
			queue => undef,
		}, status => 404);
		$sth->finish;
		return;
	}
	$sth->finish;

	if ($command eq 'update') { # if command is request for updating the operating status of the device
		# Check whether the update task is exists
		$sth = $s->tmpdb->prepare('SELECT * FROM queue WHERE device_id = ? AND command = ?;');
		$sth->execute($device_id, 'update');
		my $q = $sth->fetchrow_hashref;
		if (defined $q && defined $q->{id}) {
			$s->render(json => {
				queue => {
					id => $q->{id},
				},
			}, status => 208);
			$sth->finish;
			return;
		}
	}
	
	# Add the command into queues
	$sth = $s->tmpdb->prepare('INSERT INTO queue VALUES(?, ?, ?, ?, ?);');
	$sth->execute(undef, $s->userId(), $d->{id}, $command, time());
	my $queue_id = $s->tmpdb->sqlite_last_insert_rowid();

	# Render - Return the inserted queue-id
	$s->render(json => {
		queue => {
			id => $queue_id,
		}
	}, status => 202);
}

1;
