#!perl
use strict;
use Test::More tests => 6;
use File::Spec;
use Time::Piece qw/ :override /;


use_ok( 'JCMT::Tau::WVM' );
use_ok( 'JCMT::Tau::WVMGDGraph' );

# Set new data root
JCMT::Tau::WVM->data_root( File::Spec->catdir("t","data") );

# This test only works at the JAC
# start time is 20041108T03:00
# end time is 20041108T04:00

my $wvm = new JCMT::Tau::WVM( start_time => scalar gmtime( 1099874757 ),
			      end_time => scalar gmtime( 1099944757 )
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
