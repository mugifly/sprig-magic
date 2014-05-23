package SprigMagic::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub top {
	my $s = shift;
	$s->redirect_to('/admin/users');
}

sub users {
	my $s = shift;

	if (defined $s->param('action')) {
		my $action = $s->param('action');
		my $user_id = $s->param('user_id');
		if ($user_id eq $s->userId()) {
			$s->flash('message_error', '自分自身の変更はできません');
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

	# Find users
	my @users = ();
	my $sth = $s->db->prepare('SELECT * FROM user;');
	$sth->execute();
	while (my $user = $sth->fetchrow_hashref) {
		push(@users, $user);
	}
	$sth->finish();

	$s->stash('users', \@users);
	$s->render(users => \@users);
}

1;
