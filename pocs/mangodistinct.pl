#!/usr/bin/env perl
use v5.10;

use Mango;

# Declare a Mango helper
sub mango { state $m = Mango->new('mongodb://localhost:27017') }

# Find document
my $values = mango->db('battlerec')->collection('battles')->find()->distinct('ligue');
#my $values = $docs->dictinct("ligue");
foreach my $v (@$values) {
  print "Values : $v\n";
}
#while(my $d = $docs->next) {
#  print "Ligue : $d->{ligue}\n";
#}
