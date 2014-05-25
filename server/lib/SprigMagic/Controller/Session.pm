package SprigMagic::Controller::Session;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub auth_development {
	my $s = shift;

	if ($s->app->mode() ne 'development') {
		$s->redirect_to('/');
		return;
	}
	
	# Load the Session helper
	$s->app->plugin('SprigMagic::Helper::Session');

	# Find an user from database
	my $db_user_id = undef;
	my $sth = $s->db->prepare('SELECT * FROM user WHERE oauth_service = ? AND oauth_id = ?;');
	$sth->execute('development', 'development');
	my $user = $sth->fetchrow_hashref;
	my $user_exist = 0;
	if (defined $user && $user->{oauth_id} eq 'development') {
		$user_exist = 1;
		$db_user_id = $user->{id}
	}
	$sth->finish();

	# Upsert to database
	if ($user_exist) {
		# Update
		$sth = $s->db->prepare('UPDATE user SET last_logged_in_at = ? WHERE id = ?;');
		$sth->execute('development', time());
		$sth->finish();
	} else {
		# Insert as Administrator
		$sth = $s->db->prepare('INSERT INTO user VALUES (?, ?, ?, ?, ?)');
		$sth->execute(undef, 'development', 'development', 10, time());
		$sth->finish();
		# Check the inserted user-id
		$sth = $s->db->prepare('SELECT * FROM user WHERE oauth_service = ? AND oauth_id = ?;');
		$sth->execute('development', 'development');
		$user = $sth->fetchrow_hashref;
		$db_user_id = $user->{id};
		$sth->finish();
	}

	# Generate the session
	my $session_id = $s->generate_session_id('DEVELOPMENT'); # Generate a string with using helper
	$sth = $s->db->prepare('INSERT INTO session VALUES (?, ?, ?, ?, ?)');
	$sth->execute($session_id, $db_user_id, time(), $s->tx->remote_address, $s->req->headers->user_agent);
	$sth->finish();

	# Serve the session-cookie, And redirect to top page
	$s->session(expiration => $s->config->{session_expires});
	$s->session('session_id', $session_id);
	$s->redirect_to('/');
}

sub oauth_google_redirect {
	my $s = shift;

	# Load the Session helper
	$s->app->plugin('SprigMagic::Helper::Session');
	# Initialize the OAuth client
	my $oauth = $s->oauth_client_google;
	
	# Redirect to the authorization page
	$s->redirect_to($oauth->authorize());
}

sub oauth_google_callback {
	my $s = shift;

	# Load the Session helper
	$s->app->plugin('SprigMagic::Helper::Session');
	# Initialize the OAuth client
	my $oauth = $s->oauth_client_google;

	# Get an access token
	my $access_token;
	eval {
		$access_token = $oauth->get_access_token($s->param('code'));
	};
	if($@){
		$s->flash('message_error','認証に失敗しました。再度ログインしてください。');
		$s->redirect_to('/?token_invalid');
		$s->app->log->debug("Session - token_invalid: $@");
		return;
	}

	# Get a user data
	my $response = $access_token->get('https://www.googleapis.com/oauth2/v1/userinfo');
	if (!$response->is_success) {
		$s->flash('message_error','Googleアカウント情報の取得に失敗しました。再度ログインしてください。');
		$s->redirect_to('/?userinfo_invalid');
		$s->app->log->debug("Session - userinfo_invalid");
		return;
	}
	my $profile = Mojo::JSON::decode_json($response->decoded_content());
	my $oauth_id = $profile->{email};

	# Get the number of all users
	my $num_of_user = $s->db->selectrow_array('SELECT count(*) FROM user;');

	# Find an user from database
	my $db_user_id = undef;
	my $sth = $s->db->prepare('SELECT * FROM user WHERE oauth_service = ? AND oauth_id = ?;');
	$sth->execute('google', $oauth_id);
	my $user = $sth->fetchrow_hashref;
	my $user_exist = 0;
	if (defined $user && $user->{oauth_id} eq $oauth_id) {
		$user_exist = 1;
		$db_user_id = $user->{id}
	}
	$sth->finish();

	# Upsert to database
	if ($user_exist) {
		# Update
		$sth = $s->db->prepare('UPDATE user SET last_logged_in_at = ? WHERE id = ?;');
		$sth->execute($oauth_id, time());
		$sth->finish();
	} else {
		# Insert
		my $user_status = ($s->config->{require_user_activation}) ? 0 : 1; # 1 = normal, 0 = not activated
		if ($num_of_user == 0) {
			$user_status = 10; # First user must be administrator
		}

		$sth = $s->db->prepare('INSERT INTO user VALUES (?, ?, ?, ?, ?)');
		$sth->execute(undef, 'google', $oauth_id, $user_status, time());
		$sth->finish();
		# Check the inserted user-id
		$sth = $s->db->prepare('SELECT * FROM user WHERE oauth_service = ? AND oauth_id = ?;');
		$sth->execute('google', $oauth_id);
		$user = $sth->fetchrow_hashref;
		$db_user_id = $user->{id};
		$sth->finish();
	}

	# Generate the session
	my $session_id = $s->generate_session_id($oauth_id); # Generate a string with using helper
	$sth = $s->db->prepare('INSERT INTO session VALUES (?, ?, ?, ?, ?)');
	$sth->execute($session_id, $db_user_id, time(), $s->tx->remote_address, $s->req->headers->user_agent);
	$sth->finish();

	# Serve the session-cookie, And redirect to top page
	$s->session(expiration => $s->config->{session_expires});
	$s->session('session_id', $session_id);
	$s->redirect_to('/');
}

1;
