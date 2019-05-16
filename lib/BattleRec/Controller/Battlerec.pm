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

  my @battles;

  my %elo = ();
  my %xp = ();

  my $pcount = mango->db("battlerec")->collection("pbattles")->find()->count();
  if($pcount > 0) {
    print "TAKE FROM PRECOMPUTED PBATTLES\n";
    my $docs = mango->db("battlerec")->collection("pbattles")->find()->sort({ date => -1 })->limit(1000);
    while (my $d = $docs->next) { 
      my %battle = ();
      foreach my $k (keys %$d) {
        $battle{$k} = $d->{$k};
      }
      push @battles, \%battle;
    }
  } else {
    my $docs = mango->db("battlerec")->collection("battles")->find()->sort({ date => -1 })->limit(1000);
    while (my $d = $docs->next) { 
      my %battle = ();
      foreach my $k (keys %$d) {
        $battle{$k} = $d->{$k};
      }

      my $DW = 0; my $EW = 0;
      if($d->{resultat} eq "V") { $DW = 1; $EW = 0; } 
      elsif($d->{resultat} eq "D") { $DW = 0; $EW = 1; }
      elsif($d->{resultat} eq "N") { $DW = 0.5; $EW = 0.5; }
     
      
      if(not defined($elo{$d->{mc1}})) { $elo{$d->{mc1}} = 1800; }
      if(not defined($elo{$d->{mc2}})) { $elo{$d->{mc2}} = 1800; }

      my $P = 1 / ( 1 + 10 ** (( ($elo{$d->{mc2}} - $elo{$d->{mc1}})) / 400  ));

      if($DW + $EW > 0) {
	my $K;
        my $J;
        if($d->{ligue} eq "Rap Contenders") { $K = 60; $J = 5;}
        elsif($d->{ligue} eq "59 Arena") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Arene") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Punch Ligue") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Punch Mania") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Punch Airline") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Central Punch") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Madison Square Garden") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Acapella Belgium Contest") { $K = 30; $J = 20; }
        elsif($d->{ligue} eq "Swiss Battlerap League") { $K = 20; $J = 30; }
        elsif($d->{ligue} eq "Battle PunchlinerZ") { $K = 20; $J = 30; }
        elsif($d->{ligue} eq "Rap Battle Revelation") { $K = 20; $J = 30;}
        elsif($d->{ligue} eq "Battle Royale") { $K = 10; $J = 40; }
        else { $K = 5; $J = 60;}

        $K = $d->{K};
        $J = $d->{J};
      
        # Coefficient different selon l'evenement
        if($DW > $EW) { 
          # Victoire MC1 
          $elo{$d->{mc1}} = $elo{$d->{mc1}} + $K * ($DW - $P);
          $elo{$d->{mc2}} = $elo{$d->{mc2}} + $J * ($EW - (1 - $P));
        } elsif($EW > $DW) { 
          # Victoire MC2
          $elo{$d->{mc1}} = $elo{$d->{mc1}} + $J * ($DW - $P);
          $elo{$d->{mc2}} = $elo{$d->{mc2}} + $K * ($EW - (1 - $P));
        } else {
          # Nul 
          if(($DW - $P) > 0) { 
            $elo{$d->{mc1}} = $elo{$d->{mc1}} + $K * ($DW - $P);
            $elo{$d->{mc2}} = $elo{$d->{mc2}} + $J * ($EW - (1 - $P));
          } elsif(($EW - (1 - $P)) > 0) {
            $elo{$d->{mc1}} = $elo{$d->{mc1}} + $J * ($DW - $P);
            $elo{$d->{mc2}} = $elo{$d->{mc2}} + $K * ($EW - (1 - $P));
          }
        }
            
      }

      #$elo{$d->{mc1}} = sprintf("%.0f", $elo{$d->{mc1}}); 
      #$elo{$d->{mc2}} = sprintf("%.0f", $elo{$d->{mc2}}); 

      # Un battle de plus pour chaque MC
      $xp{$d->{mc1}}++;
      $xp{$d->{mc2}}++;

      $battle{derniersmc1} = derniers($d->{mc1}, $d->{date});
      $battle{balancemc1} = record($d->{mc1}, $d->{date});
      $battle{derniersmc2} = derniers($d->{mc2}, $d->{date});
      $battle{balancemc2} = record($d->{mc2}, $d->{date});
    
      push @battles, \%battle;
      mango->db("battlerec")->collection("pbattles")->insert({ date =>$d->{date}, mc1 => $d->{mc1}, balancemc1 => $battle{balancemc1}, derniersmc1 => $battle{derniersmc1}, resultat => $d->{resultat}, mc2 => $d->{mc2}, balancemc2 => $battle{balancemc2}, derniersmc2 => $battle{derniersmc2}, edition => $d->{edition}, ligue => $d->{ligue}, video => $d->{video} });
    } 
  }

  
  foreach my $k (sort {$elo{$a} <=> $elo{$b}} keys %elo) {
    my $e = sprintf("%.0f", $elo{$k}); 
    print "Elo $k : $e\n";
  }

  foreach my $k (sort {$xp{$b} <=> $xp{$a}} keys %xp) {
    print "$xp{$k} : $k\n";
  }

  my $values = mango->db("battlerec")->collection("battles")->find()->distinct('ligue');
  my @ligues = @{ $values };
  my @editions = ();
    
  $self->render(battles => \@battles, ligues => \@ligues, editions => \@editions);
}

# This action will render a template
sub edition {
  my $self = shift;
  my $edition = $self->stash("edition");

  my @battles;

  my $pcount = mango->db("battlerec")->collection("pbattles")->find()->count();
  if($pcount > 0) {
    print "TAKE FROM PRECOMPUTED PBATTLES\n";
    my $docs = mango->db("battlerec")->collection("pbattles")->find({ edition => $edition })->sort({ date => -1 })->limit(1000);
    while (my $d = $docs->next) { 
      my %battle = ();
      foreach my $k (keys %$d) {
        $battle{$k} = $d->{$k};
      }
      push @battles, \%battle;
    }
  } else {
    my $docs = mango->db("battlerec")->collection("battles")->find({ edition => $edition })->sort({ date => -1 })->limit(1000);
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
      mango->db("battlerec")->collection("pbattles")->insert({ date =>$d->{date}, mc1 => $d->{mc1}, balancemc1 => $battle{balancemc1}, derniersmc1 => $battle{derniersmc1}, resultat => $d->{resultat}, mc2 => $d->{mc2}, balancemc2 => $battle{balancemc2}, derniersmc2 => $battle{derniersmc2}, edition => $d->{edition}, ligue => $d->{ligue}, video => $d->{video} });
    } 
  }
    
  my $values = mango->db("battlerec")->collection("battles")->find({ edition => $edition })->distinct('ligue');
  my @ligues = @{ $values };
  my @editions = ();
    
  $self->render(template => 'battlerec/index', battles => \@battles, ligues => \@ligues, editions => \@editions);
}

# This action will render a template
sub ligue {
  my $self = shift;
  my $ligue = $self->stash("ligue");

  my @battles;

  my $pcount = mango->db("battlerec")->collection("pbattles")->find()->count();
  if($pcount > 0) {
    print "TAKE FROM PRECOMPUTED PBATTLES\n";
    my $docs = mango->db("battlerec")->collection("pbattles")->find({ ligue => $ligue })->sort({ date => -1 })->limit(1000);
    while (my $d = $docs->next) { 
      my %battle = ();
      foreach my $k (keys %$d) {
        $battle{$k} = $d->{$k};
      }
      push @battles, \%battle;
    }
  } else {
    my $docs = mango->db("battlerec")->collection("battles")->find({ ligue => $ligue })->sort({ date => -1 })->limit(1000);
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
      mango->db("battlerec")->collection("pbattles")->insert({ date =>$d->{date}, mc1 => $d->{mc1}, balancemc1 => $battle{balancemc1}, derniersmc1 => $battle{derniersmc1}, resultat => $d->{resultat}, mc2 => $d->{mc2}, balancemc2 => $battle{balancemc2}, derniersmc2 => $battle{derniersmc2}, edition => $d->{edition}, ligue => $d->{ligue}, video => $d->{video} });
    } 
  }
    
  my @ligues = ();
  my $values = mango->db("battlerec")->collection("battles")->find({ ligue => $ligue })->distinct('edition');
  my @editions = @{ $values };
    
  $self->render(template => 'battlerec/index', battles => \@battles, ligues => \@ligues, editions => \@editions);
}

1;

