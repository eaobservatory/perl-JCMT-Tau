# Test the airmass calculation
use strict;
use Test::More tests => 2;
use Test::Number::Delta;
use JCMT::Tau;


my $el = 30.0;
my ($am, $stat) = airmass($el);

print "# Elevation: $el, Airmass: $am, Should be: 2.00\n";

is($stat, 0);
delta_within($am, 2.00, 0.01);

