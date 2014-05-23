package SprigMagic::Controller::Top;
use Mojo::Base 'Mojolicious::Controller';

sub guest {
	my $s = shift;
	$s->render();
}

sub user {
	my $s = shift;
	$s->render();
}

1;
