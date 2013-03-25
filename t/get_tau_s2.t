# -*- cperl -*-
use strict;
use Test;
BEGIN { plan tests => 9 }
use JCMT::Tau::SCUBA2;

# ================================================================
#   Test JCMT::Tau::get_tau
#
#  These tests have to be changed if the ratios are changed
#
# ================================================================

# === 1st Test: GET TAU bad parameters ===

my ($this,$stat) = get_tau("850W",'CSO',.1);

ok( $stat, -1);

# Input == output

($this, $stat) = get_tau('450','450', 0.85);
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
ok($this, '1.0');


# === Now invert
($this, $stat) = get_tau('CSO', '450', $this);
ok($stat, 0);
$this = sprintf("%.2lf",$this);
ok($this, 0.05);

