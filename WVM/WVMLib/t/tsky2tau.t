#!perl
use strict;
use Test::More tests => 4;

use_ok( 'JCMT::Tau::WVM::WVMLib' );

# 20041108 3.69056 hrs
# These reference columns are from the .wvm file
# Look in t/data in the JCMT::Tau::WVM file
#  column 0 is decimal hours

# input parameters
my $airmass = 1.33;  # col 1
my $tamb    = 277.8; # 2
my $tsky1   = 265.2; # 3
my $tsky2   = 171.6; # 4
my $tsky3   = 93.4;  # 5

# Test results
my $pwvlosref = 4.02;     # 8
my $pwvzenref = 3.02;     # 9
my $tauref    = '0.1470'; # 10

# Calculate the line of sight parameters
my $pwvlos  = JCMT::Tau::WVM::WVMLib::tsky2pwv( $airmass,
						$tamb,
						$tsky1,
						$tsky2,
						$tsky3);

print "# PWV Line-of-sight = ", $pwvlos,"\n";
is( sprintf("%4.2f", $pwvlos), $pwvlosref, "Compare line of sight pwv");

my $pwvzen = JCMT::Tau::WVM::WVMLib::pwv2zen($airmass, $pwvlos);

print "# PWV zenith        = ", $pwvzen,"\n";
is( sprintf("%4.2f", $pwvzen), $pwvzenref, "Compare zenith pwv");


my $tauzen = sprintf( "%6.4f",
		      JCMT::Tau::WVM::WVMLib::pwv2tau( $airmass, $pwvzen));

print "# Zenith tau = ", $tauzen ,"\n";

is( $tauzen, $tauref, "Compare with pre-calculated zenith tau");

