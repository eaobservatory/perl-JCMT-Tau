package JCMT::Tau::WVM::WVMLib;

=head1 NAME

JCMT::Tau::WVM::WVMLib - Interface to the WVM C library

=head1 SYNOPSIS

  use JCMT::Tau::WVM::WVMLib qw/ pwv2tau /;

  $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );

  $pwv = pwv2zen( $airmass, $pwvlos );

  $tau = pwv2tau( $airmass, $pwv );

=head1 DESCRIPTION

Perl interface to the C WVM library.


=cut


require Exporter;
require DynaLoader;

use strict;
use warnings;

use vars qw/ @ISA @EXPORT_OK $VERSION /;
$VERSION = '0.01';


@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw/ pwv2tau tsky2pwv pwv2zen /;

JCMT::Tau::WVM::WVMLib->bootstrap( $VERSION );


=head1 FUNCTIONS

=over 4

=item B<tsky2pwv>

Convert measured sky temperatures to the line-of-sight precipitable
water vapor content (mm of water).

  $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );

where $tamb is the ambient temperature and C<@tsky> are the 3 measured
sky temperatures (in kelvin).

=item B<pwv2zen>

Convert line-of-sight precipitable water vapor to the zenith value in
mm of water).

 $pwv_z = pwv2zen( $airmass, $pwvlos );

=cut

sub pwv2zen {
  my ($airmass, $pwv) = @_;
  return ( $pwv / $airmass );
}

=item B<pwv2tau>

Convert precipitable water vapor to 225GHZ tau.

  $tau = pwv2tau( $airmass, $pwv_z );

=back

=head1 COPYRIGHT

Copyright 2004 (C) Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=cut

1;
