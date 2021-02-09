# -*- cperl -*-
use strict;
use Test::More tests => 7;
use Test::Number::Delta;
use JCMT::Tau::SCUBA2;

# ================================================================
#   Test JCMT::Tau::get_tau
#
#  These tests have to be changed if the ratios are changed
#
# ================================================================

# === 1st Test: GET TAU bad parameters ===

my ($this,$stat) = get_tau("850W",'CSO',.1);

is( $stat, -1);

# Input == output

($this, $stat) = get_tau('450','450', 0.85);
is($stat, -2);
is($this, 0.85);

# Same with a space
($this, $stat) = get_tau('CSO','cso ', 428.2);
is($stat, -2);
is($this, 428.2);

# ===  GET TAU ===

($this,$stat) = get_tau(450,'CSO',.05);

is($stat, 0);
delta_within($this, 1.0, 0.1);
