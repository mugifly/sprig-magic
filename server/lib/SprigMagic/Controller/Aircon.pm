package SprigMagic::Controller::Aircon;
use Mojo::Base 'Mojolicious::Controller';

use SprigMagic::Model::Aircon;

sub top {
	my $s = shift;
	# Render a page
	$s->render();
}

# API for get the status of Aircon
sub status {
	my $s = shift;

	# Initialize the Aircon object
	my $aircon;
	eval {
		$aircon = SprigMagic::Model::Aircon->new(
			serial_port_name => $s->config->{rpi_serial_port} || '/dev/rfcomm0',
		);
	}; if($@) { $s->render(text => $@, status => 500); return; }

	my $exec_command = undef;

	if (defined $s->param('action')) {
		my $action = $s->param('action');
		if ($action eq 'set_power' && defined $s->param('power')) {
			# Turn on / off the power
			$exec_command = $action;
			$aircon->set_power($s->param('power'));
		} elsif ($action eq 'set_temperature' && defined $s->param('temperature')) {
			# Set the temperature
			$exec_command = $action;
			my $temp = $s->param('temperature');
			$temp =~ s/[^0-9]//;
			$aircon->set_temperature($temp);
		}
	}

	# Render
	if (defined $exec_command) {
		$s->render(json => {
			command => $exec_command,
		});
	} else {
		eval {
			$s->render(json => {
				aircon => {
					power => ($aircon->get_power()) ? Mojo::JSON::true : Mojo::JSON::false,
					power_value => $aircon->get_power(),
					power_brightness_sensor_value => $aircon->get_power_brightness_sensor_value(),
					temperature_set => $aircon->get_set_temperature(),
					temperature_real => $aircon->get_real_temperature(),
				},
			});
		}; if ($@) { $s->render(text => $@, status => 500); }
	}
}

1;
