use strict;
use Test;
BEGIN { plan tests => 3 }
use JCMT::Tau;

# ================================================================
#   Test JCMT::Tau::transmission
#
# ================================================================

# === 1st Test: TRANSMISSION bad parameters ===

my ($this,$stat) = transmission(0,1);
ok($stat, -1);

# === 2nd Test: TRANSMISSION ===

($this,$stat) = transmission(1.1,1);
$this = sprintf("%.1lf",$this);
ok($stat, 0);
ok($this, 0.3);
