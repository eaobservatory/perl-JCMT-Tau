#!perl

use Test::More tests => 2;

use_ok( 'JCMT::Tau::WVM::WVMLib' );

my ($airmass,$pwv) = (1.478900, 4.640000);
my $retval = sprintf("%8.6f", JCMT::Tau::WVM::WVMLib::pwv2tau($pwv));
print "# airmass: $airmass and pwv $pwv give tau of $retval\n";
is($retval, '0.202600',"Test pwv2tau");
