#!perl

use strict;
use warnings;
use Test::More tests => 4;

use_ok( "JCMT::Tau::CsoFit2" );

my $fit = JCMT::Tau::CsoFit2->new( "t/csofit2.dat" );

ok($fit, "Opened a fit file" );

# 2013-03-15T10  (obs 20130315#16)
my $startepoch = 1363344580;
my $endepoch = 1363344619;
my $subset = $fit->get( $startepoch, $endepoch);

my $starttau = $subset->tau( $startepoch );
print "# Start epoch tau = $starttau\n";

# Now use the full set of fits
my $starttau_0 = $fit->tau( $startepoch );
is( $starttau, $starttau_0, "Tau from start using 2 techniques" );

is( sprintf("%.3f", $starttau), "0.130", "Start tau");
