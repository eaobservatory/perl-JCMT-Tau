package JCMT::Tau::WVM::WVMLib;

=head1 NAME

JCMT::Tau::WVM::WVMLib - Interface to the WVM C library

=head1 SYNOPSIS

  use JCMT::Tau::WVM::WVMLib qw/ pwv2tau /;

  $tauzen = tsky2tau( $airmass, $tamb, @tsky );

  $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );

  $pwv = pwv2zen( $airmass, $pwvlos );

  $tau = pwv2tau( $airmass, $pwv );

=head1 DESCRIPTION

Perl interface to the C WVM library and a simple wrapper function
to convert sky temperatures directly to zenith opacity.


=cut


require Exporter;
require DynaLoader;

use strict;
use warnings;

use vars qw/ @ISA @EXPORT_OK $VERSION /;
$VERSION = '0.02';


@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw/ pwv2tau tsky2pwv pwv2zen tsky2tau /;

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

=item B<tsky2tau>

Convert measured sky temperatures to the zenith sky opacity.

  $tauzen = tsky2tau( $airmass, $tamb, @tsky );

where $tamb is the ambient temperature and C<@tsky> are the 3 measured
sky temperatures (in kelvin).

=cut

sub tsky2tau {
  my ($airmass, $tamb, @tsky) = @_;
  my $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );
  my $pwvzen = pwv2zen( $airmass, $pwvlos );
  return pwv2tau( $airmass, $pwvzen );
}

=back

=head1 COPYRIGHT

Copyright 2004 (C) Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=cut

1;
