package BattleRec::Controller::Battlerec;
use Mojo::Base 'Mojolicious::Controller';

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') };

# Give the battle result from the opponent point of view
sub inverser($) {
  my $res = shift;
  if($res eq "V") { return "D"; } elsif($res eq "D") { return "V"; } else { return $res; }
}

# Last results from the battle MC before a given date
sub derniers($$) {
  my $mc = shift;
  my $date = shift;

  my $docs = mango->db("battlerec")->collection("battles")->find({'$and' => [{date => {'$lt' => "$date"}} , {'$or' => [{mc1 => "$mc"}, {mc2 => "$mc"}]}]} )->sort({ date => -1 })->limit(5);
  my $lasts = "";
  while (my $d = $docs->next) { 
    if($mc eq $d->{mc1}) {
      $lasts = $d->{resultat} . $lasts; 
    } else { 
      $lasts = inverser($d->{resultat}) . $lasts; 
    }
  }
    
  return $lasts;
}

# The Victories-Draws-Looses palmares for a battle MC before a given date
sub record($$) {
  my $mc = shift;
  my $date = shift;

  my $docs = mango->db("battlerec")->collection("battles")->find({'$and' => [{date => {'$lt' => "$date"}} , {'$or' => [{mc1 => "$mc"}, {mc2 => "$mc"}]}]} )->sort({ date => -1 });
  my $v = 0;
  my $d = 0;
  my $n = 0;
  while (my $b = $docs->next) { 
    my $resultat = $b->{resultat};
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

  return "$v-$d-$n";
}

# This action will prepare an optimized table where all MC palmares is computed so that next time we just have to select and print lines
sub precompute {
    print "We have to precompute... Please wait a moment\n";
    my $docs = mango->db("battlerec")->collection("battles")->find()->sort({ date => -1 })->limit(10000);
    while (my $d = $docs->next) { 
      my %battle = ();
      foreach my $k (keys %$d) {
        $battle{$k} = $d->{$k};
      }

      $battle{derniersmc1} = derniers($d->{mc1}, $d->{date});
      $battle{balancemc1} = record($d->{mc1}, $d->{date});
      $battle{derniersmc2} = derniers($d->{mc2}, $d->{date});
      $battle{balancemc2} = record($d->{mc2}, $d->{date});
    
      mango->db("battlerec")->collection("pbattles")->insert({ date =>$d->{date}, mc1 => $d->{mc1}, balancemc1 => $battle{balancemc1}, derniersmc1 => $battle{derniersmc1}, resultat => $d->{resultat}, mc2 => $d->{mc2}, balancemc2 => $battle{balancemc2}, derniersmc2 => $battle{derniersmc2}, edition => $d->{edition}, ligue => $d->{ligue}, video => $d->{video} });
    } 
}

# This action will render the battle MC recap
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

# This action will render the main page with all battles from our database
sub index {
  my $self = shift;

  my @battles;

  my $pcount = mango->db("battlerec")->collection("pbattles")->find()->count();
  precompute() if($pcount <= 0);
  my $docs = mango->db("battlerec")->collection("pbattles")->find()->sort({ date => -1 })->limit(10000);
  while (my $d = $docs->next) { 
    my %battle = ();
    foreach my $k (keys %$d) {
      $battle{$k} = $d->{$k};
    }
    push @battles, \%battle;
  }

  my $values = mango->db("battlerec")->collection("pbattles")->find()->distinct('ligue');
  my @ligues = @{ $values };
  my @editions = ();
    
  $self->render(battles => \@battles, ligues => \@ligues, editions => \@editions);
}

# This action will render all battles from an event
sub edition {
  my $self = shift;
  my $edition = $self->stash("edition");

  my @battles;

  my $pcount = mango->db("battlerec")->collection("pbattles")->find()->count();
  precompute() if($pcount <= 0);
  my $docs = mango->db("battlerec")->collection("pbattles")->find({ edition => $edition })->sort({ date => -1 })->limit(10000);
  while (my $d = $docs->next) { 
    my %battle = ();
    foreach my $k (keys %$d) {
      $battle{$k} = $d->{$k};
    }
    push @battles, \%battle;
  }
    
  my $values = mango->db("battlerec")->collection("battles")->find({ edition => $edition })->distinct('ligue');
  my @ligues = @{ $values };
  my @editions = ();
    
  $self->render(template => 'battlerec/index', battles => \@battles, ligues => \@ligues, editions => \@editions);
}

# This action will render all battles from a league (set of events from the same organizer crew)
sub ligue {
  my $self = shift;
  my $ligue = $self->stash("ligue");

  my @battles;

  my $pcount = mango->db("battlerec")->collection("pbattles")->find()->count();
  precompute() if($pcount <= 0);
  my $docs = mango->db("battlerec")->collection("pbattles")->find({ ligue => $ligue })->sort({ date => -1 })->limit(10000);
  while (my $d = $docs->next) { 
    my %battle = ();
    foreach my $k (keys %$d) {
      $battle{$k} = $d->{$k};
    }
    push @battles, \%battle;
  }
    
  my @ligues = ();
  my $values = mango->db("battlerec")->collection("battles")->find({ ligue => $ligue })->distinct('edition');
  my @editions = @{ $values };
    
  $self->render(template => 'battlerec/index', battles => \@battles, ligues => \@ligues, editions => \@editions);
}

1;

