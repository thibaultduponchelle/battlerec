package BattleRec::Controller::Battlerec;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
  my $self = shift;
  
  # Render template "battlerec/index.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
