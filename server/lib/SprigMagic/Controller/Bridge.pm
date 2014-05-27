package SprigMagic::Controller::Bridge;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

sub login_check {
	my $s = shift;
	
	# Add the header for JavaScript
	$s->res->headers->add('Access-Control-Allow-Origin', '*');

	# Session check
	if(defined $s->session('session_id') && !defined $s->flash('session_check_skip')){
		my $session_id = $s->session('session_id');
		# Find the session from the database
		my $sth = $s->db->prepare('SELECT * FROM session WHERE id = ?;');
		$sth->execute($session_id);
		if (my $session = $sth->fetchrow_hashref) { # Found the session
			# Find the user from the database
			$sth = $s->db->prepare('SELECT * FROM user WHERE id = ?;');
			$sth->execute($session->{user_id});
			my $user = $sth->fetchrow_hashref;
			if (defined $user && $user->{id}) { # Found the user
				if ($user->{status} == -1) { # If disabled
					$s->flash('message_error', 'あなたのアカウントは無効化されています。');
					$s->flash('session_check_skip', 'true');
					$s->redirect_to('/');
					return;
				} elsif ($user->{status} == 0) { # If not activated
					$s->flash('message_error', 'あなたのアカウントはまだ管理者によりアクティベートされていません。アクティベートを要請し、後ほど再度アクセスしてください。');
					$s->flash('session_check_skip', 'true');
					$s->redirect_to('/');
					return;
				}

				# If normal user
				if ($user->{status} != 10 && $s->current_route =~ /^admin.*/) { # If user has not the admin permission
					$s->redirect_to('/dashboard');
					return;
				}
				
				# Set the user-id and user-data into the stash
				$s->stash('user_id', $user->{id});
				$s->stash('user', $user);

				if ($s->current_route eq '') {
					$s->redirect_to('/dashboard');
				}
				
				return 1; # Continue after process
			}
		}
	}
	
	# For guest user
	if ($s->current_route eq '' || $s->current_route =~ /^top.*/){
		return 1; # Continue after process
	} elsif ($s->current_route =~ /^session.*/){
		return 1; # Continue after process
	} elsif ($s->current_route eq 'github_webhook_receiver'){
		return 1; # Continue after process
	}

	# Redirect to top page (for login)
	$s->redirect_to('/');
	return 0;
}

1;