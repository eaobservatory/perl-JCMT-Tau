use strict;
no strict "vars";

use JCMT::Tau;

# ================================================================
#   Test JCMT::Tau::get_tau
#  
# ================================================================

$n=2; # number of tests
print "1..$n\n";

# === 1st Test: GET TAU bad parameters ===

($this,$stat) = get_tau(950,'CSO',.1);

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: GET TAU ===

($this,$stat) = get_tau(450,'CSO',.05);
$this = sprintf("%.1lf",$this);

($stat==0) && ($this==1) && (print "ok\n") || (print "not ok\n");

