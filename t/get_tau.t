use strict;
use Test;
BEGIN { plan tests => 11 }
use JCMT::Tau;

# ================================================================
#   Test JCMT::Tau::get_tau
#
#  These tests have to be changed if the ratios are changed
#
# ================================================================

# === 1st Test: GET TAU bad parameters ===

my ($this,$stat) = get_tau(950,'CSO',.1);

ok( $stat, -1);

# Input == output

($this, $stat) = get_tau('450W','450W', 0.85);
ok($stat, -2);
ok($this, 0.85);

# Same with a space
($this, $stat) = get_tau('CSO','cso ', 428.2);
ok($stat, -2);
ok($this, 428.2);

# ===  GET TAU ===

($this,$stat) = get_tau(450,'CSO',.05);
$this = sprintf("%.1lf",$this);

ok($stat, 0);
ok($this, '0.9');


# === Now invert
($this, $stat) = get_tau('CSO', '450', 1.0);
ok($stat, 0);
$this = sprintf("%.2lf",$this);
ok($this, 0.05);



# Request narrow band
($this, $stat) = get_tau('850W', 'CSO', 0.05);
ok($stat,0);
ok(sprintf("%.1lf",$this), 0.2);

