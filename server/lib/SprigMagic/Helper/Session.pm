package SprigMagic::Helper::Session;
use strict;
use warnings;

use base 'Mojolicious::Plugin';
use Net::OAuth2::Client;
use Mojo::Util;

sub register {
	my ($self, $app) = @_;
	
	# OAuth client for Google
	$app->helper( oauth_client_google =>
		sub {
			return Net::OAuth2::Client->new(
				$app->config()->{oauth_google_key},
				$app->config()->{oauth_google_secret},
				site	=>	'https://accounts.google.com',
				authorize_path	=>	'/o/oauth2/auth',
				access_token_path=>	'/o/oauth2/token',
				approval_prompt	=> 'auto',
				access_type => 'online',
				scope	=>	'https://www.googleapis.com/auth/userinfo.email'
			)->web_server(redirect_uri => ($app->config()->{base_url}) .'session/oauth_google_callback', access_type => 'online');
		}
	);

	# Generate the session-id
	$app->helper( generate_session_id => 
		sub {
			my $seed_id = shift;

			my $time_num = time();
			my $rand_num = int(rand(99999999999999999));

			my $key = $seed_id;
			for(my $i=0;$i<10;$i++){
				$key = Mojo::Util::hmac_sha1_sum($key, $time_num + $rand_num);
			}
			$key = Mojo::Util::b64_encode($key.$time_num);
			return($key);
		}
	);
}

1;