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
  print "$doc->{date},$doc->{mc2},$doc->{event},$doc->{resultat},$doc->{video}\n";

  my $docs = mango->db("battlerec")->collection("battles")->find({mc1 => "$name"})->sort({ date => -1 });
  while (my $d = $docs->next) {
    print "$d->{date},$d->{mc2},$d->{event},$d->{resultat},$d->{video}\n";
  }
  
  
  # Render template "battlerec/index.html.ep" with message
  $self->render(msg => 'Lamanif');
}

1;

