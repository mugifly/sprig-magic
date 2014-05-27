package SprigMagic::Controller::Develop;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;

sub github_webhook_receiver {
	my $s = shift;

	# Check the configuration
	if (!defined $s->config->{is_enable_github_webhook_receiver}) {
		$s->render('The updater is disabled.', status => 400);
	} elsif (!defined $s->config->{github_webhook_target_branch}) {
		$s->render('The webhook target branch is not specified.', status => 400);
	}

	# Read the payload
	if (!defined $s->param('payload')) {
		$s->render(text => 'Invalid parameter', status => 400);
		return;
	}

	my $payload = Mojo::JSON::decode_json($s->param('payload'));
	if ($payload->{ref} ne 'refs/heads/'.$s->config->{github_webhook_target_branch}) {
		$s->render(text => 'Not target refs', status => 400);
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
		$s->render('The updater is not found.', status => 400);
	}

	system($script_path.' '.$s->config->{github_webhook_target_branch});

	# Render
	$s->render('Started the updater.');
}

1;
