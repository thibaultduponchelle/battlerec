package BattleRec::Controller::Battlerec;
use Mojo::Base 'Mojolicious::Controller';

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') };


# This action will render a template
sub index {
  my $self = shift;
  my $name = $self->stash("name");
  
  #my @records = mango->db("battlerec")->collection("battles")->find_one({mc1: "$name"});
  my $doc = mango->db("battlerec")->collection("battles")->find_one({mc1 => "$name"});
  #foreach my $rec (@records) {
  #  print "record : $rec\n";
  #}
  print "Name : $name Doc : $doc\n";
  
  
  # Render template "battlerec/index.html.ep" with message
  $self->render(msg => 'Lamanif');
}

1;

