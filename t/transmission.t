use strict;
use Test::More tests => 3;
use Test::Number::Delta;
use JCMT::Tau;

# ================================================================
#   Test JCMT::Tau::transmission
#
# ================================================================

# === 1st Test: TRANSMISSION bad parameters ===

my ($this,$stat) = transmission(0,1);
is($stat, -1);

# === 2nd Test: TRANSMISSION ===

($this,$stat) = transmission(1.1,1);
is($stat, 0);
delta_within($this, 0.3, 0.1);
