package SprigMagic::Controller::Categories;
use Mojo::Base 'Mojolicious::Controller';

sub categories_list {
	my $s = shift;

	# Listup categoies
	my $categories_hashref = {};
	my $sth = $s->db->prepare('SELECT * FROM device;');
	$sth->execute;
	while (my $c = $sth->fetchrow_hashref) {
		if (defined $categories_hashref->{$c->{category_name}}) {
			$categories_hashref->{$c->{category_name}}->{num_of_devices}++;
		} else {
			$categories_hashref->{$c->{category_name}} = {
				name => $c->{category_name},
				num_of_devices => 1,
			};
		}
	}
	$s->stash(categories => $categories_hashref);

	# Render
	$s->render();
}

sub category_devices {
	my $s = shift;
	my $category_name = $s->param('category_name');

	# Check whether exists that category
	my $sth = $s->db->prepare('SELECT * FROM device WHERE category_name = ?;');
	$sth->execute($category_name);
	if (!defined $sth->fetchrow_hashref) {
		$s->render(text => 'リクエストされたカテゴリはありません。', status => 404);
		return;
	}

	# Render
	$s->render();
}

1;
