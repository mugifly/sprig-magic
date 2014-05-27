package SprigMagic::Controller::Develop;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;

sub github_webhook_receiver {
	my $s = shift;

	# Check the configuration
	if (!defined $s->config->{is_enable_github_webhook_receiver}) {
		$s->render(text => 'The updater is disabled.', status => 400);
		return;
	} elsif (!defined $s->config->{github_webhook_target_branch}) {
		$s->render(text => 'The webhook target branch is not specified.', status => 400);
		return;
	}

	# Read the payload
	my $payload = undef;
	if (defined $s->param('payload')) {
		$payload = Mojo::JSON::decode_json(Mojo$s->param('payload'));
	} else {
		eval {
			$payload = Mojo::JSON::decode_json($s->req->body);
		};
	}

	if (!defined $payload) {
		$s->render(text => 'Invalid parameter', status => 400);
		return;
	}

	if ($payload->{ref} ne 'refs/heads/'.$s->config->{github_webhook_target_branch}) {
		$s->render(text => 'Not target refs', status => 400);
		return;
	}

	# Exec the repository updater
	my $script_dir = $s->app->home->rel_dir('script');
	my $script_path = undef;
	if (-f "${script_dir}/repository_updater.production.sh") {
		$script_path = "${script_dir}/repository_updater.production.sh";
	} elsif (-f "${script_dir}/repository_updater.sh") {
		$script_path = "${script_dir}/repository_updater.sh";
	}

	if (!defined $script_path) {
		$s->render(text => 'The updater is not found.', status => 400);
		return;
	}

	system($script_path.' '.$s->config->{github_webhook_target_branch});

	# Render
	$s->render(text => 'Started the updater.');
}

1;
