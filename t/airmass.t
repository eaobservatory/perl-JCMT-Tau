# Test the airmass calculation

use JCMT::Tau;
use strict;

my $n = 1;

print "1..$n\n";

my $el = 30.0;
my ($am, $stat) = airmass($el);

$am = sprintf "%5.2f", $am;

print "Elevation: $el, Airmass: $am, Should be: 2.00\n";

($stat==0) && ($am==2) && (print "ok\n") || (print "not ok\n");
