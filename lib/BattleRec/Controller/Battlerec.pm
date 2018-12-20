package BattleRec::Controller::Battlerec;
use Mojo::Base 'Mojolicious::Controller';

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') };

sub derniers($) {
  my $mc = shift;
  my $docs = mango->db("battlerec")->collection("battles")->find({mc1 => "$mc"})->sort({ date => -1 });
  my $lasts = "";
  while (my $d = $docs->next) { $lasts .= $d->{resultat}; }
  print "MC : $mc Lasts : $lasts\n";

  return $lasts;
}

sub record($) {
  my $mc = shift;
  my $docs = mango->db("battlerec")->collection("battles")->find({mc1 => "$mc"})->sort({ date => -1 });
  my $v = 0;
  my $d = 0;
  my $n = 0;
  while (my $b = $docs->next) { 
    #if($b->{resultat} eq "V") { 
    #  $v++;
    #} elsif($b->{resultat} eq "D") {
    #  $d++;
    #} else { 
    #  $n++;
    #}
  }

  print "MC : $mc Record : $v-$d-$n\n";

  return "$v-$d-$n";
}
 



# This action will render a template
sub mc {
  my $self = shift;
  my $name = $self->stash("name");
  
  my $docs = mango->db("battlerec")->collection("battles")->find({mc1 => "$name"})->sort({ date => -1 });
  my %derniers = (); 
  my %record = (); 
  while (my $d = $docs->next) { 
    $derniers{$d->{mc2}} = derniers($d->{mc2}); 
    $record{$d->{mc2}} = record($d->{mc2}); 
  } 

  $docs->rewind;
  
  $self->render(msg => 'Lamanif', battles => $docs, derniers => \%derniers, record => \%record);
}

# This action will render a template
sub event {
  my $self = shift;
  my $event = $self->stash("event");
  
  my $docs = mango->db("battlerec")->collection("battles")->find({event => "$event"})->sort({ date => -1 });
  #while (my $d = $docs->next) { #  print "$d->{date},$d->{mc2},$d->{event},$d->{resultat},$d->{video}\n"; #}
  
  $self->render(msg => 'Lamanif', battles => $docs);
}

1;

