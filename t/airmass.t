# Test the airmass calculation
use strict;
use Test;
BEGIN { plan tests => 2 }
use JCMT::Tau;


my $el = 30.0;
my ($am, $stat) = airmass($el);

$am = sprintf "%5.2f", $am;

print "# Elevation: $el, Airmass: $am, Should be: 2.00\n";

ok($stat, 0);
ok($am,' 2.00');

