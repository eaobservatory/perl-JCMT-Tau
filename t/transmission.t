use strict;
no strict "vars";

use JCMT::Tau;

# ================================================================
#   Test JCMT::Tau::transmission
#  
# ================================================================

$n=2; # number of tests
print "1..$n\n";

# === 1st Test: TRANSMISSION bad parameters ===

($this,$stat) = transmission(0,1);

($stat==-1) && (print "ok\n") || (print "not ok\n");



# === 2nd Test: TRANSMISSION ===

($this,$stat) = transmission(1.1,1);
$this = sprintf("%.1lf",$this);

($stat==0) && ($this==.3) && (print "ok\n") || (print "not ok\n");
