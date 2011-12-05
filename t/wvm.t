#!perl
use strict;
use Test::More tests => 6;
use File::Spec;
use DateTime;


use_ok( 'JCMT::Tau::WVM' );

# Set new data root
JCMT::Tau::WVM->data_root( File::Spec->catdir("t","wvmdata") );

# This test only works at the JAC
# start time is 20041108T03:00
# end time is 20041108T04:00

my $wvm = new JCMT::Tau::WVM( start_time => DateTime->from_epoch( epoch => 1099874757, time_zone => 'UTC' ),
			      end_time => DateTime->from_epoch( epoch => 1099944757, time_zone => 'UTC' )
			    );

isa_ok( $wvm, "JCMT::Tau::WVM" );

my ($min, $max) = $wvm->tbounds;
is( $min, 1099883962, 'earliest time');
is( $max, 1099885286, 'latest time');

# stats
my @stats = $wvm->stats;
print "# Mean: $stats[0] +/- $stats[1] Median: $stats[2]\n";
is( $stats[2], 0.142, "Median" );

my @rows = $wvm->table;

# 1000 rows read but only 845 stored due to rounding errors at
# 1 second resolution
is( scalar(@rows), 845, "Count number of rows in table");
print join("\n",map { "# ". $_ } @rows),"\n";
exit;
