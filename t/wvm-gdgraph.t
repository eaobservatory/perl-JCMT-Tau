#!perl
use strict;
use Test::More;
use File::Spec;
use DateTime;

# Need GD::Graph to continue
BEGIN {
  my $retval = eval "use GD::Graph; 1;";
  if (!defined $retval) {
    plan skip_all => "GD::Graph module not available";
    exit;
  } else {
    plan tests => 6;
  }
}


use_ok( 'JCMT::Tau::WVM' );
use_ok( 'JCMT::Tau::WVM::WVMGDGraph' );

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


my $gd = $wvm->graph;
isa_ok( $gd, 'GD::Image' );
open my $img, "> test.png" or die "error opening PNG";
print $img $gd->png;
close($img);
