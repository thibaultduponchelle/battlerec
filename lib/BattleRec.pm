package BattleRec;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/mc/:name')->to('battlerec#mc');
  $r->get('/edition/:edition')->to('battlerec#edition');
  $r->get('/ligue/:ligue')->to('battlerec#ligue');
  $r->get('/')->to('battlerec#index');
}

1;
