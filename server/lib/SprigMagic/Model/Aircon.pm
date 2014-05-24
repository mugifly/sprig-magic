package SprigMagic::Model::Aircon;
use warnings;
use strict;
use utf8;

use Device::SerialPort;

sub new {
	my ($class, %hash) = @_;
	my $s = bless({}, $class);

	$s->{serial_port_name} = $hash{serial_port_name} || die('Not specified the serial_port');

	# Initialize the serial port
	$s->{serial} = Device::SerialPort->new($s->{serial_port_name}) || die('Cant open the serial port');
	$s->{serial}->user_msg("ON"); 
	$s->{serial}->baudrate(9600);
	$s->{serial}->databits(8);
	$s->{serial}->parity('none');
	$s->{serial}->stopbits(1);
	$s->{serial}->write_settings(1);
	$s->{serial}->lookclear();

	return $s;
}

# Get the power state of aircon
sub get_power {
	my $s = shift;
	$s->send_serial('get_power;');
	my $res = $s->read_serial(50000);
	if ($res =~ /power=(true|false);/) {
		if ($1 eq "true") {
			return 1;
		}
		return 0;
	}
	die ("Can not parse the response: $res");
}

# Turn on / off the power
sub set_power {
	my ($s, $power) = @_;
	if ($power eq 'true') {
		$s->send_serial('set_power=true;');
	} else {
		$s->send_serial('set_power=false;');
	}
}

# Get a value of the power brightness sensor
sub get_power_brightness_sensor_value {
	my $s = shift;
	$s->send_serial('get_power_brightness_sensor_value;');
	my $res = $s->read_serial(100000);
	if ($res =~ /power_brightness_sensor_value=([0-9]+);/) {
		return $1 + 0;
	}
	die ("Can not parse the response: $res");
}

# Get a temperature from temperature sensor
sub get_real_temperature {
	my $s = shift;
	$s->send_serial('get_realtemp;');
	my $res = $s->read_serial(50000);
	if ($res =~ /realtemp=([0-9\.]+);/) {
		return $1 + 0;
	}
	die ("Can not parse the response: $res");
}

# Get a set-temperature
sub get_set_temperature {
	my $s = shift;
	$s->send_serial('get_settemp;');
	my $res = $s->read_serial(50000);
	if ($res =~ /settemp=([\-0-9\.]+);/) {
		my $set_temp = $1 + 0;
		if ($set_temp == -1) {
			return undef;
		}
		return $set_temp;
	}
	die ("Can not parse the response: $res");
}

# Set a temperature
sub set_temperature {
	my ($s, $temperature) = @_;
	$s->send_serial('set_temp=' . $temperature . ';');
}

# Send a string with using the serial port
sub send_serial {
	my ($s, $str) = @_;
	$s->{serial}->write($str) || die ('Cant write to the serial port');
}

# Read a string from the serial port
sub read_serial {
	my ($s, $wait) = @_;
	if (!defined $wait) {
		$wait = 1000;
	}
	my $res = "";
	for (my $i = 0; $i < $wait; $i++) {
		my $r = $s->{serial}->lookfor();
		if (defined $r && $r ne "" && $r ne '\r') {
			$res .=  $r;
		}
	}
	return $res;
}

1;