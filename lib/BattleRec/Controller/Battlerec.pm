package BattleRec::Controller::Battlerec;
use Mojo::Base 'Mojolicious::Controller';

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') };

sub inverser($) {
  my $res = shift;
  if($res eq "V") { return "D"; } elsif($res eq "D") { return "V"; } else { return $res; }
}

sub derniers($$) {
  my $mc = shift;
  my $date = shift;

  print "Date : $date\n";
  my $docs = mango->db("battlerec")->collection("battles")->find({'$and' => [{date => {'$lt' => "$date"}} , {'$or' => [{mc1 => "$mc"}, {mc2 => "$mc"}]}]} )->sort({ date => -1 })->limit(5);
  my $lasts = "";
  while (my $d = $docs->next) { 
    if($mc eq $d->{mc1}) {
      $lasts = $d->{resultat} . $lasts; 
    } else { 
      $lasts = inverser($d->{resultat}) . $lasts; 
    }
  }
    
  print "MC : $mc Lasts : $lasts\n";

  return $lasts;
}

sub record($$) {
  my $mc = shift;
  my $date = shift;

  my $docs = mango->db("battlerec")->collection("battles")->find({'$and' => [{date => {'$lt' => "$date"}} , {'$or' => [{mc1 => "$mc"}, {mc2 => "$mc"}]}]} )->sort({ date => -1 });
  my $v = 0;
  my $d = 0;
  my $n = 0;
  while (my $b = $docs->next) { 
    my $resultat = $b->{resultat};
    print "$mc resultat : $resultat\n";
    if($mc eq $b->{mc2}) {
      $resultat = inverser($resultat);
    }
    if($resultat eq "V") { 
      $v++;
    } elsif($resultat eq "D") {
      $d++;
    } elsif($resultat eq "N") {
      $n++;
    }
  }

  print "MC : $mc Record : $v-$d-$n\n";

  return "$v-$d-$n";
}
 
# This action will render a template
sub mc {
  my $self = shift;
  my $name = $self->stash("name");
  
  my $docs = mango->db("battlerec")->collection("battles")->find({'$or' => [{mc1 => "$name"}, {mc2 => "$name"}]})->sort({ date => -1 });
  my @battles;
  while (my $d = $docs->next) { 
    my %battle = ();
    foreach my $k (keys %$d) {
      $battle{$k} = $d->{$k};
    }
    if($d->{mc1} eq $name) {
      $battle{derniers} = derniers($d->{mc2}, $d->{date});
      $battle{balance} = record($d->{mc2}, $d->{date});
    } else {
      $battle{derniers} = derniers($d->{mc1}, $d->{date});
      $battle{balance} = record($d->{mc1}, $d->{date});
    }
    push @battles, \%battle;
  } 

  my $balance = record($name, "3099-12-12"); 
  $self->render(mc => $name, battles => \@battles, balance => $balance);
}

# This action will render a template
sub index {
  my $self = shift;
  
  my $docs = mango->db("battlerec")->collection("battles")->find()->sort({ date => -1 })->limit(1000);
  
  my @battles;

  while (my $d = $docs->next) { 
    my %battle = ();
    foreach my $k (keys %$d) {
      $battle{$k} = $d->{$k};
    }
    $battle{derniersmc1} = derniers($d->{mc1}, $d->{date});
    $battle{balancemc1} = record($d->{mc1}, $d->{date});
    $battle{derniersmc2} = derniers($d->{mc2}, $d->{date});
    $battle{balancemc2} = record($d->{mc2}, $d->{date});
    
    push @battles, \%battle;
  } 
    
  $self->render(battles => \@battles);
}

1;

