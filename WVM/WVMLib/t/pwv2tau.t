# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
# BEGIN { $| = 1; print "1..1\n"; }
# END {print "not ok 1\n" unless $loaded;}
BEGIN { plan tests => 2 };
use WvmTau;
#$loaded = 1;
#print "ok 1\n";
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my ($airmass,$pwv) = (1.478900, 4.640000);
my $retval = sprintf("%8.6f", WvmTau::pwv2tau($airmass,$pwv));
print("airmass: $airmass and pwv $pwv give tau of $retval\n");
ok($retval, 0.221604);
