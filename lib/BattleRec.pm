package BattleRec;
use Mojo::Base 'Mojolicious';

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') };


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
  $r->get('/event/:event')->to('battlerec#event');
  $r->get('/')->to('battlerec#index');
}

1;
