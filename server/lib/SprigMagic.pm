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
		if (!-f $db_filename) {
			die ('[NOTICE] Please initialize the database with using the sprig_magic_cmd command.');
			return;
		}
		my $dbh = DBI->connect('dbi:SQLite:'.$db_filename, '', '', {PrintError => 1, RaiseError => 1}) || die ('Can not open the database');
		return $dbh;
	});

	# Temporary database helper
	$s->helper(tmpdb => sub {
		my $tmpdb_filename = shift->config->{temp_db_filename} || '/tmp/sprigmagic_tmp.db';
		my $is_init = (-f $tmpdb_filename) ? 0 : 1;
		my $tmpdbh = DBI->connect('dbi:SQLite:'.$tmpdb_filename, '', '', {PrintError => 1, RaiseError => 1}) || die ('Can not open the temporary database');
		if ($is_init) {
			# Queues
			$tmpdbh->do(qq| CREATE TABLE queue (
				id INTEGER PRIMARY KEY,
				user_id INTEGER NOT NULL,
				device_id INTEGER NOT NULL,
				command TEXT NOT NULL,
				created_at INTEGER NOT NULL
			); |);
			# Temporary Key-and-Values store for each device modules
			$tmpdbh->do(qq| CREATE TABLE device_tmp_kvs (
				key TEXT UNIQUE NOT NULL,
				value TEXT NOT NULL
			); |);
		}
		return $tmpdbh;
	});

	# User helper
	$s->helper(user => sub { my $s = shift; my $h = $s->db->prepare('SELECT * FROM user WHERE id = ?;'); $h->execute($s->stash('user_id')); return $h->fetchrow_hashref; });
	$s->helper(userId => sub { return shift->stash('user_id'); });

	# Set the configuration of cookie
	$s->app->sessions->cookie_name($config->{session_name} || 'sprigmagic');
	$s->app->secrets($config->{session_secrets});
	
	# Support for the reverse proxy
	$ENV{MOJO_REVERSE_PROXY} = 1;
	$s->hook('before_dispatch' => sub {
		my $s = shift;
		if ( $s->req->headers->header('X-Forwarded-Host') && defined($s->config->{base_path})) {
			# Set the base-path (directory path)
			my @basepaths = split(/\//, $s->config->{base_path});
			shift @basepaths;
			foreach my $part(@basepaths){
				if($part eq ${$s->req->url->path->parts}[0]){
					push @{$s->req->url->base->path->parts}, shift @{$s->req->url->path->parts};
				} else {
					last;
				}
			}
		}
	});

	# Router
	my $r = $s->routes;
	# Set the class for Controllers
	$r->namespaces(['SprigMagic::Controller']); # lib/SprigMagic/Controller/

	# Set the bridge
	$r = $r->bridge->to('bridge#login_check');

	# Normal route to controller
	$r->get('/')->to('top#guest');
	$r->get('/dashboard')->to('top#user');
	$r->route('/admin')->to('admin#top');
	$r->route('/admin/devices')->to('admin#devices');
	$r->route('/admin/users')->to('admin#users');
	$r->get('/session/auth_development')->to('session#auth_development');
	$r->get('/session/oauth_google_redirect')->to('session#oauth_google_redirect');
	$r->get('/session/oauth_google_callback')->to('session#oauth_google_callback');

	$r->get('/devices' => [format => [qw(html)]])->to('devices#devices_list');
	$r->get('/devices' => [format => [qw(json)]])->to('devices#devices_list_api');
	$r->get('/devices')->to('devices#devices_list');

	$r->get('/devices/:device_id' => [format => [qw(html)]])->to('devices#device_detail');
	$r->get('/devices/:device_id' => [format => [qw(json)]])->to('devices#device_detail_api');
	$r->get('/devices/:device_id')->to('devices#device_detail');
	
	$r->post('/devices/:device_id')->to('devices#device_post');
	
	$r->get('/categories')->to('categories#categories_list');
	$r->route('/categories/:category_name')->to('categories#category_devices');
	
	$r->get('/queues')->to('queues#queues_get');

	$r->post('/github_webhook_receiver')->to('develop#github_webhook_receiver');
}

1;
