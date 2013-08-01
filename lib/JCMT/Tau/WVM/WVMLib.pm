package JCMT::Tau::WVM::WVMLib;

=head1 NAME

JCMT::Tau::WVM::WVMLib - Interface to the WVM C library

=head1 SYNOPSIS

  use JCMT::Tau::WVM::WVMLib qw/ pwv2tau /;

  $tauzen = tsky2tau( $airmass, $tamb, @tsky );

  $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );

  $pwv = pwv2zen( $airmass, $pwvlos );

  $tau = pwv2tau( $airmass, $pwv );

  $tau = pwv2tau_bydate( $mjdate, $airmass, $pwv );

=head1 DESCRIPTION

Perl interface to the C WVM library and a simple wrapper function
to convert sky temperatures directly to zenith opacity.


=cut

use strict;
use warnings;
use Carp;

use Exporter 'import';
use base qw/ DynaLoader /;

use vars qw/ @ISA @EXPORT_OK $VERSION /;

# Module::Build seems to insist that this version matches
# the dist version because that is what is used to defined
# XS_VERSION in the XS C code.
$VERSION = '1.11';

@EXPORT_OK = qw/ pwv2tau tsky2pwv pwv2zen tsky2tau wvmOpt wvmEst
                 tsky2expected wvmOptMulti
                 pwv2tau_bydate tsky2pwv_bydate /;

JCMT::Tau::WVM::WVMLib->bootstrap( $VERSION );


=head1 FUNCTIONS

=over 4

=item B<tsky2pwv>

Convert measured sky temperatures to the line-of-sight precipitable
water vapor content (mm of water).

  $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );

where $tamb is the ambient temperature and C<@tsky> are the 3 measured
sky temperatures (in kelvin).

=item B<wvmOpt>

Convert measured sky temperatures to the line-of-sight precipitable
water vapor (mm of water), the excess broad band line of sight opacity,
and the effective temperature.

 ($pwvlos, $tau0, $tWat) = wvmOpt( $airmass, $tamb, @tsky );

It will return identical values to tsky2pwv for water vapor content.

Matches the low-level wvmOpt C function.

=item B<wvmEst>

Convert airmass, pwv line of sight, excess broad band opacity and
water temperature to expected brightness temperature, total opacity
and effective temperature for each of the three WVM channels.

 (\@tbri, \@ttau, \@teff, \@aeff) = wvmEst( $airmass, $pwvlos,
                                            $tWat, $tau0 );

Matches the low-level wvmEst C function.

=item tsky2expected

Combines wvmOpt and wvmEst to return the expected state from the
measured values.

 (\@tbri, \@ttau, \@teff, \@aeff) = tsky2expected( $airmass, $tamb,
                                                   @tsky );

=cut

sub tsky2expected {
  my ($pwv, $tau0, $tWat) = wvmOpt( @_ );
  return wvmEst( $_[0], $pwv, $tWat, $tau0 );
}

=item B<pwv2zen>

Convert line-of-sight precipitable water vapor to the zenith value in
mm of water).

 $pwv_z = pwv2zen( $airmass, $pwvlos );

croaks if passed a zero airmass.

=cut

sub pwv2zen {
  my ($airmass, $pwv) = @_;
  croak "Can not convert line-of-sight pwv of $pwv at airmass $airmass to zenith value"
    if $airmass < 1.00;
  return ( $pwv / $airmass );
}

=item B<pwv2tau>

Convert zenith precipitable water vapor to 225GHZ tau. This uses
the current conversion factor.

  $tau = pwv2tau( $pwv_z );

=item B<pwv2tau_bydate>

Convert zenith precipitable water vapor to 225 GHz tau using the
appropriate conversion formulae based on the date of observation.

  $tau = pw2vtau_bydate( $mjd, $pwv_z );

where $mjd is the modified Julian date.

=item B<tsky2tau>

Convert measured sky temperatures to the zenith sky opacity.

  $tauzen = tsky2tau( $airmass, $tamb, @tsky );

where $tamb is the ambient temperature and C<@tsky> are the 3 measured
sky temperatures (in kelvin).

If the airmass is zero the sky opacity is zero.

=cut

sub tsky2tau {
  # Call the bydate routine with an unreasonably large date for current value
  return tsky2tau_bydate( 1_000_000.0, @_ );
}

=item B<tsky2tau_bydate>

Convert measured sky temperatures to the zenith sky opacity for a given date

  $tauzen = tsky2tau( $mjd, $airmass, $tamb, @tsky );

where $mjd is the modified Julian date, $tamb is the ambient temperature
and C<@tsky> are the 3 measured sky temperatures (in kelvin).

If the airmass is zero the sky opacity is zero.

=cut

sub tsky2tau_bydate {
  my ($mjd, $airmass, $tamb, @tsky) = @_;
  return 0.0 if $airmass < 0.00001;
  my $pwvlos = tsky2pwv( $airmass, $tamb, @tsky );
  my $pwvzen = pwv2zen( $airmass, $pwvlos );
  return pwv2tau_bydate( $mjd, $pwvzen );
}

=back

=head1 COPYRIGHT

Copyright (C) 2010-2011,2013 Science and Technology Facilities Council.
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
