use strict;
use Test::More tests => 11;
use Test::Number::Delta;
use JCMT::Tau;

# ================================================================
#   Test JCMT::Tau::get_tau
#
#  These tests have to be changed if the ratios are changed
#
# ================================================================

# === 1st Test: GET TAU bad parameters ===

my ($this,$stat) = get_tau(950,'CSO',.1);

is( $stat, -1);

# Input == output

($this, $stat) = get_tau('450W','450W', 0.85);
is($stat, -2);
is($this, 0.85);

# Same with a space
($this, $stat) = get_tau('CSO','cso ', 428.2);
is($stat, -2);
is($this, 428.2);

# ===  GET TAU ===

($this,$stat) = get_tau(450,'CSO',.05);

is($stat, 0);
delta_within($this, 0.9, 0.1);


# === Now invert
($this, $stat) = get_tau('CSO', '450', 1.0);
is($stat, 0);
delta_within($this, 0.05, 0.01);



# Request narrow band
($this, $stat) = get_tau('850W', 'CSO', 0.05);
is($stat,0);
delta_within($this, 0.2, 0.1);

