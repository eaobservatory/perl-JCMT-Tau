#!perl
use strict;
use Test::More tests => 7;

use_ok( 'JCMT::Tau::WVM::WVMLib' );

# 20041108 3.69056 hrs
# These reference columns are from the .wvm file
# Look in t/data in the JCMT::Tau::WVM file
#  column 0 is decimal hours

# input parameters
my $airmass = 1.33;  # col 1
my $tamb    = 277.8; # 2
my $tsky1   = 265.2; # 3
my $tsky2   = 171.6; # 4
my $tsky3   = 93.4;  # 5

# Test results
my $pwvlosref = 4.07;     # 8
my $pwvzenref = 3.06;     # 9
my $tauref    = '0.1390'; # 10

# Calculate the line of sight parameters
my $pwvlos  = JCMT::Tau::WVM::WVMLib::tsky2pwv( $airmass,
						$tamb,
						$tsky1,
						$tsky2,
						$tsky3);

print "# PWV Line-of-sight = ", $pwvlos,"\n";
is( sprintf("%4.2f", $pwvlos), $pwvlosref, "Compare line of sight pwv");

my $pwvzen = JCMT::Tau::WVM::WVMLib::pwv2zen($airmass, $pwvlos);

print "# PWV zenith        = ", $pwvzen,"\n";
is( sprintf("%4.2f", $pwvzen), $pwvzenref, "Compare zenith pwv");


my $tauzen = sprintf( "%6.4f",
		      JCMT::Tau::WVM::WVMLib::pwv2tau( $pwvzen));

print "# Zenith tau = ", $tauzen ,"\n";

is( $tauzen, $tauref, "Compare with pre-calculated zenith tau");

# Now do it in one go using the wrapper routine
my $tauzen2 = sprintf( "%6.4f",
    JCMT::Tau::WVM::WVMLib::tsky2tau( $airmass, $tamb, $tsky1, $tsky2, $tsky3 ));

is( $tauzen2, $tauzen, "Compare with wrapper function");

# Make sure that wvmOpt gives same answer as tsky2pwv

my ($pwvlos_opt, $tau0_opt, $tWat_opt) = JCMT::Tau::WVM::WVMLib::wvmOpt( $airmass,
                                                                         $tamb,
                                                                         $tsky1,
                                                                         $tsky2,
                                                                         $tsky3);
is( $pwvlos, $pwvlos_opt, "wvmOpt");
print "# WVMOPT => $pwvlos_opt, $tau0_opt, $tWat_opt\n";

# Now try wvmEst

my @results = JCMT::Tau::WVM::WVMLib::wvmEst( $airmass, $pwvlos_opt, $tWat_opt, $tau0_opt);

print "# Chan  TMEAS    TBRI  TTAU    TEFF  AEFF\n";
my @tskys = ($tsky1, $tsky2, $tsky3);
for my $i (0..$#{$results[0]}) {
  printf "# $i   %7.3f %7.3f  %4.2f %7.3f  %4.2f\n",
    $tskys[$i],
    $results[0]->[$i],
      $results[1]->[$i],
        $results[2]->[$i],
          $results[3]->[$i];
}

# Now combo
my @results2 = JCMT::Tau::WVM::WVMLib::tsky2expected( $airmass, $tamb, @tskys );
is( $results2[0][0], $results[0][0], "First brightness");
