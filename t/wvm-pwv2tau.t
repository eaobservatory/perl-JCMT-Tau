#!perl

use strict;
use Test::More tests => 2;
use Test::Number::Delta;

use_ok( 'JCMT::Tau::WVM::WVMLib' );

my ($airmass,$pwv) = (1.478900, 4.640000);
my $retval = JCMT::Tau::WVM::WVMLib::pwv2tau_bydate(56_000.0, $pwv);
print "# airmass: $airmass and pwv $pwv give tau of $retval\n";
delta_within($retval, '0.202600', 0.000001, "Test pwv2tau");
