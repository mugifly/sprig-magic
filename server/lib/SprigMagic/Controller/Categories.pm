package SprigMagic::Controller::Categories;
use Mojo::Base 'Mojolicious::Controller';

sub aircon {
	my $s = shift;
	$s->render();
}

1;
