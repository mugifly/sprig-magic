package SprigMagic::Controller::Queues;
use Mojo::Base 'Mojolicious::Controller';

sub queues_get {
	my $s = shift;

	my @my_queues = ();

	my $sth = $s->tmpdb->prepare('SELECT * FROM queue WHERE user_id = ?;');
	$sth->execute($s->userId());
	while (my $q = $sth->fetchrow_hashref) {
		push(@my_queues, $q);
	}

	$s->render(json => {
		queues => \@my_queues,
	});
}

1;
