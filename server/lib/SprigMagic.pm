package SprigMagic;
use Mojo::Base 'Mojolicious';
use DBI;

sub startup {
	my $s = shift;

	# Read the configuration
	my $config = $s->plugin('Config' => {file => 'config/sprig_magic.conf'});

	# Database helper
	$s->helper(db => sub {
		my $db_filename = shift->config->{db_filename} || 'sprigmagic.db';
		my $is_init = (-f $db_filename) ? 0 : 1;
		my $dbh = DBI->connect('dbi:SQLite:'.$db_filename, '', '', {PrintError => 1, RaiseError => 1}) || die ('Can not open the database');
		if ($is_init) {
			# Initialize the database
			$dbh->do(qq| CREATE TABLE user (
				id integer primary key,
				oauth_service TEXT,
				oauth_id TEXT,
				status integer not null,
				last_logged_in_at integer
			); |);
			$dbh->do(qq| CREATE TABLE session (
				id TEXT unique not null,
				user_id integer not null,
				logged_in_at integer not null,
				ip_address TEXT,
				user_agent TEXT
			); |);
			$dbh->do(qq| CREATE TABLE kv (
				key TEXT primary key,
				value TEXT not null
			); |);
		}
		return $dbh;
	});

	# User helper
	$s->helper(user => sub { my $s = shift; my $h = $s->db->prepare('SELECT * FROM user WHERE id = ?;'); $h->execute($s->stash('user_id')); return $h->fetchrow_hashref; });
	$s->helper(userId => sub { return shift->stash('user_id'); });

	# Set the configuration of cookie
	$s->app->sessions->cookie_name($config->{session_name} || 'sprigmagic');
	$s->app->secrets($config->{session_secrets});

	# Router
	my $r = $s->routes;
	# Set the class for Controllers
	$r->namespaces(['SprigMagic::Controller']); # lib/SprigMagic/Controller/

	# Set the bridge
	$r = $r->bridge->to('bridge#login_check');

	# Normal route to controller
	$r->get('/')->to('top#guest');
	$r->get('/dashboard')->to('top#user');
	$r->get('/admin')->to('admin#top');
	$r->get('/admin/users')->to('admin#users');
	$r->get('/session/oauth_google_redirect')->to('session#oauth_google_redirect');
	$r->get('/session/oauth_google_callback')->to('session#oauth_google_callback');
	$r->get('/aircon')->to('aircon#top');
	$r->route('/aircon/status')->to('aircon#status');
}

1;
