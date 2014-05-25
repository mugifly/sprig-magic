# Device helper
package SprigMagic::Helper::Device;
use strict;
use warnings;

use base 'Mojolicious::Plugin';
use FindBin;

sub register {
	my ($self, $app) = @_;

	# Listup names of the device module
	$app->helper( get_device_module_names => 
		sub {
			my @names = ();
			my $module_dir = "${FindBin::Bin}/../../lib/SprigMagic/Model/Device/";
			opendir(my $dirh, $module_dir) || die("Can not open the module directory: ${module_dir}");
			foreach (readdir($dirh)) {
				next if /^\.{1,2}$/;
				if ($_ =~ /^(\w+)\.pm$/ && $_ ne 'Base.pm') {
					push(@names, $1);
				}
			}
			closedir($dirh);
			return @names;
		}
	);

	# Get an instance of the device module
	$app->helper( get_device_module => 
		sub {
			my ($s, $module_name, $device_id, $device_name, $connect_port, $dbh, $tmpdbh) = @_;
			return get_device_module($module_name, $device_id, $device_name, $connect_port, $dbh, $tmpdbh);
		}
	);
}

# Get an instance of the device module
sub get_device_module {
	my ($module_name, $device_id, $device_name, $connect_port, $dbh, $tmpdbh) = @_;
	my %params = (
		device_id => undef,
		device_name => $device_name,
		connect_port => $connect_port,
		# Prepare the methods for called from the device module.
		db_methods => {
			persistence_data_updater => sub { # Method for update the persistence-data; It will called from the device module.
				my $json_obj = shift; # JSON 
				my $sth = $dbh->prepare('UPDATE device SET data = ?, updated_at = ? WHERE id = ?;');
				$sth->execute(Mojo::JSON::encode_json($json_obj), time(), $device_id);
				$sth->finish();
			},
			tmpkvs_getter => sub { # Method for fetch a value from the temporary-kvs; It will called from the device module.
				my $key = shift;
				if ($key ne 'OPERATING_STATUS' && $key ne 'OPERATING_STATUS_UPDATED_AT') {
					$key =~ s/[^0-9A-Za-z]//g;
					$key =~ tr/A-Z/a-z/;
				}
				my $sth = $tmpdbh->prepare('SELECT * FROM device_tmp_kvs WHERE key = ?;');
				$sth->execute($device_id.'_'.$key);
				my $kv = $sth->fetchrow_hashref;
				$sth->finish();
				return $kv->{value} if (defined $kv && $kv->{key});
				return undef;
			},
			tmpkvs_setter => sub { # Method for set a value into the temporary-kvs; It will called from the device module.
				my ($key, $value) = @_;
				if ($key eq 'OPERATING_STATUS') {
					# Store the date into the temporary database
					my $sth = $tmpdbh->prepare('INSERT OR REPLACE INTO device_tmp_kvs VALUES (?, ?);');
					$sth->execute($device_id.'_OPERATING_STATUS_UPDATED_AT', time());
					$sth->finish();
				} else {
					$key =~ s/[^0-9A-Za-z]//g;
					$key =~ tr/A-Z/a-z/;
				}
				# Store a value into the temporary database
				my $sth = $tmpdbh->prepare('INSERT OR REPLACE INTO device_tmp_kvs VALUES (?, ?);');
				$sth->execute($device_id.'_'.$key, $value);
				$sth->finish();
			},
			queue_inserter => sub { # Method for insert a command into queues; It will called from the device module.
				my ($command) = @_;
				my $sth = $tmpdbh->prepare('INSERT INTO queue VALUES(?, ?, ?, ?, ?);');
				$sth->execute(undef, -1, $device_id, $command, time());
				$sth->finish();
			},
		},
	);
	my $module = undef;
	eval "require SprigMagic::Model::Device::${module_name}; \$module = SprigMagic::Model::Device::${module_name}->new(\%params);";
	if ($@) {
		die 'Error occurred at device helper: '.$@;
	}
	return $module;
}



1;