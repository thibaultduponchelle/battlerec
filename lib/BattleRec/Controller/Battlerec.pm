package BattleRec::Controller::Battlerec;
use Mojo::Base 'Mojolicious::Controller';

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') };

sub inverser($) {
  my $res = shift;
  if($res eq "V") { return "D"; } elsif($res eq "D") { return "V"; } else { return $res; }
}

sub derniers($) {
  my $mc = shift;
  my $docs = mango->db("battlerec")->collection("battles")->find({'$or' => [{mc1 => "$mc"}, {mc2 => "$mc"}]})->sort({ date => -1 })->limit(6);
  my $lasts = "";
  while (my $d = $docs->next) { 
    if($mc eq $d->{mc1}) {
      $lasts .= $d->{resultat}; 
    } else { 
      $lasts .= inverser($d->{resultat}); 
    }
  }
    
  print "MC : $mc Lasts : $lasts\n";

  return $lasts;
}

sub record($) {
  my $mc = shift;
  my $docs = mango->db("battlerec")->collection("battles")->find({'$or' => [{mc1 => "$mc"}, {mc2 => "$mc"}]})->sort({ date => -1 });
  my $v = 0;
  my $d = 0;
  my $n = 0;
  while (my $b = $docs->next) { 
    if($mc eq $b->{mc1}) {
      if($b->{resultat} eq "V") { 
        $v++;
      } elsif($b->{resultat} eq "D") {
        $d++;
      } else { 
        $n++;
      }
    } else { 
       if($b->{resultat} eq "V") { 
        $d++;
      } elsif($b->{resultat} eq "D") {
        $v++;
      } else { 
        $n++;
      }
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
  my %derniers = (); 
  my %balance = (); 
  while (my $d = $docs->next) { 
    if($d->{mc1} eq $name) {
      $derniers{$d->{mc2}} = derniers($d->{mc2}); 
      $balance{$d->{mc2}} = record($d->{mc2}); 
    } else {
      $derniers{$d->{mc1}} = derniers($d->{mc1}); 
      $balance{$d->{mc1}} = record($d->{mc1}); 
    }

  } 
    
  $balance{$name} = record($name); 

  $docs->rewind;
  
  $self->render(mc => $name, battles => $docs, derniers => \%derniers, balance => \%balance);
}

# This action will render a template
sub index {
  my $self = shift;
  
  my $docs = mango->db("battlerec")->collection("battles")->find()->sort({ date => -1 })->limit(1000);

  my %derniers = (); 
  my %balance = (); 
  while (my $d = $docs->next) { 
    $derniers{$d->{mc2}} = derniers($d->{mc2}); 
    $balance{$d->{mc2}} = record($d->{mc2}); 
    $derniers{$d->{mc1}} = derniers($d->{mc1}); 
    $balance{$d->{mc1}} = record($d->{mc1}); 
  } 
    
  $docs->rewind;
  $self->render(battles => $docs, derniers => \%derniers, balance => \%balance);
}

1;

